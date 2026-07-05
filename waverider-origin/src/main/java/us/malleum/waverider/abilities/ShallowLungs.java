package us.malleum.waverider.abilities;

import com.starshootercity.abilities.types.VisibleAbility;
import net.kyori.adventure.key.Key;
import org.bukkit.entity.Player;
import org.bukkit.event.EventHandler;
import org.bukkit.event.Listener;
import org.bukkit.event.entity.EntityAirChangeEvent;
import org.jetbrains.annotations.NotNull;

/**
 * Breath drains twice as fast underwater: whenever the server lowers the
 * player's air, the decrease is doubled. Air recovery at the surface (and
 * Respiration's slowed drain) are untouched - whatever the delta is, it doubles.
 */
public class ShallowLungs implements VisibleAbility, Listener {
    /** Vanilla's drowning floor: air is clamped here, and damage ticks while at it. */
    private static final int MIN_AIR = -20;

    @Override
    public @NotNull Key getKey() {
        return Key.key("waverider:shallow_lungs");
    }

    @Override
    public String title() {
        return "Shallow Lungs";
    }

    @Override
    public String description() {
        return "You belong on the water, not in it: your breath runs out twice as fast.";
    }

    @EventHandler(ignoreCancelled = true)
    public void onAirChange(EntityAirChangeEvent event) {
        if (!(event.getEntity() instanceof Player player)) return;
        this.runForAbility(player, p -> {
            int current = p.getRemainingAir();
            int next = event.getAmount();
            if (next < current) {
                event.setAmount(Math.max(MIN_AIR, current - (current - next) * 2));
            }
        });
    }
}
