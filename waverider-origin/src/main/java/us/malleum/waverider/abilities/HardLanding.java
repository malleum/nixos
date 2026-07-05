package us.malleum.waverider.abilities;

import com.starshootercity.abilities.types.VisibleAbility;
import com.starshootercity.util.config.ConfigManager;
import net.kyori.adventure.key.Key;
import org.bukkit.entity.Player;
import org.bukkit.event.EventHandler;
import org.bukkit.event.Listener;
import org.bukkit.event.entity.EntityDamageEvent;
import org.bukkit.plugin.java.JavaPlugin;
import org.jetbrains.annotations.NotNull;

import java.util.Collections;

/**
 * Double damage from falling and from flying into blocks. Runs after
 * WaterClutch's LOW-priority cancel, so a caught fall is never doubled.
 */
public class HardLanding implements VisibleAbility, Listener {
    private double multiplier;

    @Override
    public @NotNull Key getKey() {
        return Key.key("waverider:hard_landing");
    }

    @Override
    public String title() {
        return "Hard Landing";
    }

    @Override
    public String description() {
        return "The unyielding earth is not your element: you take twice as much damage from falling and from flying into blocks.";
    }

    @Override
    public void initialize(JavaPlugin plugin) {
        multiplier = this.registerConfigOption(plugin, "multiplier",
                Collections.singletonList("Fall / kinetic damage multiplier"),
                ConfigManager.SettingType.DOUBLE, 2.0);
    }

    @EventHandler(ignoreCancelled = true)
    public void onDamage(EntityDamageEvent event) {
        if (event.getCause() != EntityDamageEvent.DamageCause.FALL
                && event.getCause() != EntityDamageEvent.DamageCause.FLY_INTO_WALL) return;
        if (!(event.getEntity() instanceof Player player)) return;
        this.runForAbility(player, p -> event.setDamage(event.getDamage() * multiplier));
    }
}
