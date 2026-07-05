package us.malleum.waverider;

import com.starshootercity.OriginsAddon;
import com.starshootercity.abilities.types.Ability;
import org.jetbrains.annotations.NotNull;
import us.malleum.waverider.abilities.FluidWalker;
import us.malleum.waverider.abilities.HardLanding;
import us.malleum.waverider.abilities.LeatherOnly;
import us.malleum.waverider.abilities.ShallowLungs;
import us.malleum.waverider.abilities.WaterClutch;

import java.util.List;

/**
 * Origins-Reborn addon adding the Waverider origin.
 *
 * The origin itself is defined in resources/origins/waverider.json (extracted
 * by Origins-Reborn into plugins/Waverider-Origin/origins/ on first run); the
 * classes in {@link us.malleum.waverider.abilities} implement its custom powers.
 */
public class WaveriderOrigin extends OriginsAddon {
    private static WaveriderOrigin instance;

    public static WaveriderOrigin getInstance() {
        return instance;
    }

    @Override
    public void onRegister() {
        instance = this;
    }

    @Override
    public @NotNull String getNamespace() {
        return "waverider";
    }

    @Override
    public @NotNull List<Ability> getRegisteredAbilities() {
        return List.of(
                new FluidWalker(),
                new WaterClutch(),
                new HardLanding(),
                new ShallowLungs(),
                new LeatherOnly()
        );
    }
}
