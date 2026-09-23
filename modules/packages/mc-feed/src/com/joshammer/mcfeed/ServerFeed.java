package com.joshammer.mcfeed;

import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;

import net.kyori.adventure.text.Component;
import net.kyori.adventure.text.serializer.plain.PlainTextComponentSerializer;

import org.bukkit.Location;
import org.bukkit.advancement.Advancement;
import org.bukkit.entity.Player;
import org.bukkit.event.EventHandler;
import org.bukkit.event.EventPriority;
import org.bukkit.event.Listener;
import org.bukkit.event.entity.PlayerDeathEvent;
import org.bukkit.event.player.PlayerAdvancementDoneEvent;
import org.bukkit.event.player.PlayerCommandPreprocessEvent;
import org.bukkit.event.player.PlayerInteractEvent;
import org.bukkit.event.player.PlayerJoinEvent;
import org.bukkit.event.player.PlayerMoveEvent;
import org.bukkit.event.player.PlayerQuitEvent;
import org.bukkit.plugin.java.JavaPlugin;

import io.papermc.paper.advancement.AdvancementDisplay;
import io.papermc.paper.event.player.AsyncChatEvent;

/**
 * The server half of the Matrix bridge.
 *
 * It knows nothing about Matrix. It exposes a small HTTP API on loopback and
 * the bot process (modules/services/_mc-matrix-bot.py) does the talking, which
 * keeps an access token, a /sync connection and a pile of Python out of the
 * server JVM. The two halves share nothing but a port and a bearer token, both
 * written by modules/services/mc.nix.
 *
 *   GET /events   long-poll. Blocks until an event is queued or the wait
 *                 elapses, then drains the whole queue. One consumer only.
 *   GET /status   who is online right now, and how long each of them has gone
 *                 without touching a control.
 *
 * Both require "Authorization: Bearer <token>". The server binds 127.0.0.1, so
 * the token guards against other *local* users, not the internet.
 *
 * Like KeepInvList this registers no command and no permission: a player
 * cannot see that it is installed, and nothing a player can type reaches it.
 */
public final class ServerFeed extends JavaPlugin implements Listener {
    /**
     * Events waiting for the bot to collect them. Bounded, and the oldest is
     * dropped when it fills: a bot that has been down for an hour should come
     * back to the last few deaths, not replay the entire hour, and the server
     * must never block on a queue nobody is draining.
     */
    private final BlockingQueue<String> pending = new ArrayBlockingQueue<>(256);

    /**
     * Last time each online player gave any sign of being at the keyboard,
     * in System.currentTimeMillis(). Written from the main thread (every
     * listener here is a sync event bar chat) and read from the HTTP threads,
     * hence the concurrent map.
     */
    private final Map<UUID, Long> lastActive = new ConcurrentHashMap<>();

    private HttpServer http;
    private byte[] token = new byte[0];
    private long afkMillis = 300_000L;

    private static final PlainTextComponentSerializer PLAIN =
            PlainTextComponentSerializer.plainText();

    @Override
    public void onEnable() {
        saveDefaultConfig();

        afkMillis = getConfig().getLong("afk-seconds", 300L) * 1000L;

        final String tokenFile = getConfig().getString("token-file", "");
        try {
            token = Files.readString(Path.of(tokenFile)).trim()
                    .getBytes(StandardCharsets.UTF_8);
        } catch (final IOException e) {
            getLogger().severe("cannot read token-file " + tokenFile + ": " + e.getMessage());
        }
        if (token.length == 0) {
            getLogger().severe("no API token, the feed stays off");
            return;
        }

        final int port = getConfig().getInt("listen-port", 8765);
        try {
            http = HttpServer.create(new InetSocketAddress("127.0.0.1", port), 0);
        } catch (final IOException e) {
            getLogger().severe("cannot listen on 127.0.0.1:" + port + ": " + e.getMessage());
            return;
        }
        http.createContext("/events", this::handleEvents);
        http.createContext("/status", this::handleStatus);
        // Long-polling holds a thread for the length of the poll, so this
        // cannot be the default (synchronous, one-at-a-time) executor.
        http.setExecutor(Executors.newCachedThreadPool());
        http.start();

        // A reload while players are online would otherwise leave everyone
        // already connected with no activity stamp at all.
        for (final Player player : getServer().getOnlinePlayers()) {
            touch(player);
        }

        getServer().getPluginManager().registerEvents(this, this);
        getLogger().info("feed on 127.0.0.1:" + port
                + ", afk after " + (afkMillis / 1000L) + "s");
    }

    @Override
    public void onDisable() {
        if (http != null) {
            http.stop(0);
        }
    }

    /// ───────────────────────────── activity ─────────────────────────────

    private void touch(final Player player) {
        lastActive.put(player.getUniqueId(), System.currentTimeMillis());
    }

    /**
     * Any movement at all, the head included: turning to look at something is
     * the clearest sign of a person, and a mouse-jiggle is what an AFK check
     * is trying to catch anyway.
     *
     * This does mean the usual AFK machines read as active -- somebody in a
     * boat, a minecart, or a water stream is "moving". Catching those would
     * take input tracking the API does not expose, and the failure is the
     * harmless direction: the list says present when they are only nearly
     * present.
     */
    @EventHandler(priority = EventPriority.MONITOR, ignoreCancelled = true)
    public void onMove(final PlayerMoveEvent event) {
        final Location from = event.getFrom();
        final Location to = event.getTo();
        if (to == null) {
            return;
        }
        if (from.getX() != to.getX() || from.getY() != to.getY() || from.getZ() != to.getZ()
                || from.getYaw() != to.getYaw() || from.getPitch() != to.getPitch()) {
            touch(event.getPlayer());
        }
    }

    @EventHandler(priority = EventPriority.MONITOR, ignoreCancelled = true)
    public void onInteract(final PlayerInteractEvent event) {
        touch(event.getPlayer());
    }

    @EventHandler(priority = EventPriority.MONITOR, ignoreCancelled = true)
    public void onChat(final AsyncChatEvent event) {
        touch(event.getPlayer());
    }

    @EventHandler(priority = EventPriority.MONITOR, ignoreCancelled = true)
    public void onCommand(final PlayerCommandPreprocessEvent event) {
        touch(event.getPlayer());
    }

    /// ────────────────────────────── events ──────────────────────────────

    @EventHandler(priority = EventPriority.MONITOR)
    public void onJoin(final PlayerJoinEvent event) {
        final Player player = event.getPlayer();
        touch(player);
        emit("join", player.getName(), null);
    }

    @EventHandler(priority = EventPriority.MONITOR)
    public void onQuit(final PlayerQuitEvent event) {
        final Player player = event.getPlayer();
        lastActive.remove(player.getUniqueId());
        emit("quit", player.getName(), null);
    }

    /**
     * MONITOR, and nothing here mutates the event: KeepInvList runs at HIGHEST
     * and decides whether the items drop, so by the time this sees the death
     * the outcome is settled and this only reports it.
     */
    @EventHandler(priority = EventPriority.MONITOR)
    public void onDeath(final PlayerDeathEvent event) {
        final Component message = event.deathMessage();
        emit("death", event.getEntity().getName(),
                message == null ? null : PLAIN.serialize(message));
    }

    /**
     * Every advancement the game itself would announce in chat, and nothing
     * else. The ones with no display are the hidden recipe unlocks -- there
     * are hundreds of those per player and they are not achievements in any
     * sense a person means.
     */
    @EventHandler(priority = EventPriority.MONITOR)
    public void onAdvancement(final PlayerAdvancementDoneEvent event) {
        final Advancement advancement = event.getAdvancement();
        final AdvancementDisplay display = advancement.getDisplay();
        if (display == null || !display.doesAnnounceToChat()) {
            return;
        }

        final String kind = switch (display.frame()) {
            case CHALLENGE -> "challenge";
            case GOAL -> "goal";
            default -> "task";
        };
        emit("advancement", event.getPlayer().getName(),
                PLAIN.serialize(display.title()), kind);
    }

    private void emit(final String type, final String player, final String text) {
        emit(type, player, text, null);
    }

    private void emit(final String type, final String player, final String text,
            final String kind) {
        final StringBuilder json = new StringBuilder(128);
        json.append("{\"type\":").append(quote(type))
                .append(",\"player\":").append(quote(player));
        if (text != null) {
            json.append(",\"text\":").append(quote(text));
        }
        if (kind != null) {
            json.append(",\"kind\":").append(quote(kind));
        }
        json.append('}');

        // Oldest out, newest in: offer() on a full queue would silently drop
        // the event that just happened instead of the one nobody is waiting
        // for any more.
        while (!pending.offer(json.toString())) {
            pending.poll();
        }
    }

    /// ─────────────────────────────── HTTP ───────────────────────────────

    private boolean authorised(final HttpExchange exchange) throws IOException {
        final String header = exchange.getRequestHeaders().getFirst("Authorization");
        final String offered = header == null || !header.startsWith("Bearer ")
                ? ""
                : header.substring(7).trim();
        // isEqual is the length-independent comparison; String.equals is not.
        if (MessageDigest.isEqual(offered.getBytes(StandardCharsets.UTF_8), token)) {
            return true;
        }
        respond(exchange, 401, "{\"error\":\"unauthorised\"}");
        return false;
    }

    private static void respond(final HttpExchange exchange, final int code, final String body)
            throws IOException {
        final byte[] bytes = body.getBytes(StandardCharsets.UTF_8);
        exchange.getResponseHeaders().set("Content-Type", "application/json");
        exchange.sendResponseHeaders(code, bytes.length);
        try (OutputStream out = exchange.getResponseBody()) {
            out.write(bytes);
        }
    }

    /**
     * Long poll. Waits up to ?wait= seconds for the first event rather than
     * returning an empty list straight away, so the bot can sit in a tight
     * loop without polling the server hundreds of times an hour for nothing.
     */
    private void handleEvents(final HttpExchange exchange) throws IOException {
        try (exchange) {
            if (!authorised(exchange)) {
                return;
            }

            long wait = 25L;
            final String query = exchange.getRequestURI().getQuery();
            if (query != null && query.startsWith("wait=")) {
                try {
                    wait = Math.clamp(Long.parseLong(query.substring(5)), 0L, 60L);
                } catch (final NumberFormatException ignored) {
                    // Keep the default rather than failing the request.
                }
            }

            final List<String> batch = new ArrayList<>();
            try {
                final String first = pending.poll(wait, TimeUnit.SECONDS);
                if (first != null) {
                    batch.add(first);
                    pending.drainTo(batch);
                }
            } catch (final InterruptedException e) {
                Thread.currentThread().interrupt();
            }

            respond(exchange, 200, "{\"events\":[" + String.join(",", batch) + "]}");
        }
    }

    /**
     * The online list, built on the main thread: getOnlinePlayers and
     * everything reachable from it belong to the server tick, and reading them
     * from an HTTP thread is the classic way to get a corrupt answer or a
     * ConcurrentModificationException out of Bukkit.
     */
    private void handleStatus(final HttpExchange exchange) throws IOException {
        try (exchange) {
            if (!authorised(exchange)) {
                return;
            }

            final Future<String> body = getServer().getScheduler()
                    .callSyncMethod(this, this::statusJson);
            try {
                respond(exchange, 200, body.get(5, TimeUnit.SECONDS));
            } catch (final InterruptedException e) {
                Thread.currentThread().interrupt();
                respond(exchange, 503, "{\"error\":\"interrupted\"}");
            } catch (final Exception e) {
                // A tick that takes more than five seconds to come round, or a
                // shutdown mid-request. Either way the bot should say the
                // server is not answering, not hang.
                respond(exchange, 503, "{\"error\":\"server busy\"}");
            }
        }
    }

    private String statusJson() {
        final long now = System.currentTimeMillis();
        final StringBuilder json = new StringBuilder(256);
        json.append("{\"afkSeconds\":").append(afkMillis / 1000L).append(",\"online\":[");

        boolean first = true;
        for (final Player player : getServer().getOnlinePlayers()) {
            final long idle = now - lastActive.getOrDefault(player.getUniqueId(), now);
            if (!first) {
                json.append(',');
            }
            first = false;
            json.append("{\"name\":").append(quote(player.getName()))
                    .append(",\"idle\":").append(idle / 1000L)
                    .append(",\"afk\":").append(idle >= afkMillis)
                    .append('}');
        }

        return json.append("]}").toString();
    }

    /**
     * Minimal JSON string literal. Player names are [A-Za-z0-9_], but death
     * messages carry item and mob names players chose, so this has to be
     * correct rather than merely adequate.
     */
    private static String quote(final String raw) {
        final StringBuilder out = new StringBuilder(raw.length() + 2).append('"');
        for (int i = 0; i < raw.length(); i++) {
            final char c = raw.charAt(i);
            switch (c) {
                case '"' -> out.append("\\\"");
                case '\\' -> out.append("\\\\");
                case '\n' -> out.append("\\n");
                case '\r' -> out.append("\\r");
                case '\t' -> out.append("\\t");
                default -> {
                    if (c < 0x20) {
                        out.append(String.format(Locale.ROOT, "\\u%04x", (int) c));
                    } else {
                        out.append(c);
                    }
                }
            }
        }
        return out.append('"').toString();
    }
}
