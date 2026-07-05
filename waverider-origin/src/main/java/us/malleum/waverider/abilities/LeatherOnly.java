package us.malleum.waverider.abilities;

import com.destroystokyo.paper.MaterialTags;
import com.starshootercity.abilities.types.VisibleAbility;
import com.starshootercity.events.PlayerSwapOriginEvent;
import com.starshootercity.util.config.ConfigManager;
import net.kyori.adventure.key.Key;
import org.bukkit.Material;
import org.bukkit.entity.Player;
import org.bukkit.event.Cancellable;
import org.bukkit.event.EventHandler;
import org.bukkit.event.Listener;
import org.bukkit.event.block.BlockDispenseArmorEvent;
import org.bukkit.event.inventory.ClickType;
import org.bukkit.event.inventory.InventoryAction;
import org.bukkit.event.inventory.InventoryClickEvent;
import org.bukkit.event.inventory.InventoryDragEvent;
import org.bukkit.event.inventory.InventoryType;
import org.bukkit.event.player.PlayerInteractEvent;
import org.bukkit.inventory.EntityEquipment;
import org.bukkit.inventory.ItemStack;
import org.bukkit.plugin.java.JavaPlugin;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

import java.util.Collections;
import java.util.List;

/**
 * Only leather armor may be worn (the elytra, granting no protection, is
 * permitted). Modeled on Origins-Reborn's own LightArmor: equip attempts via
 * inventory click/drag, hotbar swap, right-click and dispensers are cancelled,
 * and disallowed pieces are stripped when the origin is gained.
 */
public class LeatherOnly implements VisibleAbility, Listener {
    private List<Material> allowedTypes;

    @Override
    public @NotNull Key getKey() {
        return Key.key("waverider:leather_only");
    }

    @Override
    public String title() {
        return "Featherweight";
    }

    @Override
    public String description() {
        return "Heavy plate would drag you under: you can only wear leather armor. An elytra still fits.";
    }

    @Override
    public void initialize(JavaPlugin plugin) {
        allowedTypes = this.registerConfigOption(plugin, "allowed-armor",
                Collections.singletonList("Armor items the Waverider may wear"),
                ConfigManager.SettingType.MATERIAL_LIST,
                List.of(Material.LEATHER_HELMET, Material.LEATHER_CHESTPLATE,
                        Material.LEATHER_LEGGINGS, Material.LEATHER_BOOTS, Material.ELYTRA));
    }

    @EventHandler
    public void onPlayerSwapOrigin(PlayerSwapOriginEvent event) {
        if (event.getNewOrigin() == null) return;
        this.runForAbility(event.getPlayer(), player -> {
            EntityEquipment equipment = player.getEquipment();
            stripPiece(player, equipment.getHelmet(), () -> equipment.setHelmet(null));
            stripPiece(player, equipment.getChestplate(), () -> equipment.setChestplate(null));
            stripPiece(player, equipment.getLeggings(), () -> equipment.setLeggings(null));
            stripPiece(player, equipment.getBoots(), () -> equipment.setBoots(null));
        });
    }

    private void stripPiece(Player player, @Nullable ItemStack piece, Runnable remove) {
        if (piece == null || piece.getType().isAir() || allowedTypes.contains(piece.getType())) return;
        remove.run();
        for (ItemStack overflow : player.getInventory().addItem(piece).values()) {
            player.getWorld().dropItemNaturally(player.getLocation(), overflow);
        }
    }

    @EventHandler
    public void onInventoryClick(InventoryClickEvent event) {
        if (!(event.getWhoClicked() instanceof Player player)) return;
        if (event.getCursor() != null && isArmor(event.getCursor().getType())
                && event.getSlotType() == InventoryType.SlotType.ARMOR) {
            checkArmorEvent(event, player, event.getCursor());
        }
        if (event.isShiftClick()) {
            ItemStack item = event.getCurrentItem();
            if (item == null) return;
            if (event.getInventory().getType() != InventoryType.CRAFTING) return;
            EntityEquipment equipment = player.getEquipment();
            if (MaterialTags.HELMETS.isTagged(item.getType()) && isEmpty(equipment.getHelmet())
                    || MaterialTags.CHESTPLATES.isTagged(item.getType()) && isEmpty(equipment.getChestplate())
                    || MaterialTags.LEGGINGS.isTagged(item.getType()) && isEmpty(equipment.getLeggings())
                    || MaterialTags.BOOTS.isTagged(item.getType()) && isEmpty(equipment.getBoots())) {
                checkArmorEvent(event, player, item);
            }
        }
        if (event.getAction() == InventoryAction.HOTBAR_SWAP && event.getHotbarButton() == -1
                && event.getSlotType() == InventoryType.SlotType.ARMOR) {
            checkArmorEvent(event, player, player.getInventory().getItemInOffHand());
        }
        if (event.getClick() == ClickType.NUMBER_KEY && event.getSlotType() == InventoryType.SlotType.ARMOR) {
            ItemStack item = player.getInventory().getItem(event.getHotbarButton());
            if (item != null) checkArmorEvent(event, player, item);
        }
    }

    @EventHandler
    public void onInventoryDrag(InventoryDragEvent event) {
        if (!(event.getWhoClicked() instanceof Player player)) return;
        for (int slot : event.getInventorySlots()) {
            if (slot >= 36 && slot <= 39) { // armor slots
                checkArmorEvent(event, player, event.getOldCursor());
                return;
            }
        }
    }

    @EventHandler
    public void onPlayerInteract(PlayerInteractEvent event) {
        if (!event.getAction().isRightClick() || event.getItem() == null) return;
        if (isArmor(event.getItem().getType())) {
            checkArmorEvent(event, event.getPlayer(), event.getItem());
        }
    }

    @EventHandler
    public void onBlockDispenseArmor(BlockDispenseArmorEvent event) {
        if (event.getTargetEntity() instanceof Player player) {
            checkArmorEvent(event, player, event.getItem());
        }
    }

    private void checkArmorEvent(Cancellable event, Player p, ItemStack armor) {
        this.runForAbility(p, player -> {
            if (!allowedTypes.contains(armor.getType()) && isArmor(armor.getType())) {
                event.setCancelled(true);
            }
        });
    }

    private boolean isEmpty(@Nullable ItemStack item) {
        return item == null || item.getType().isAir();
    }

    private boolean isArmor(Material material) {
        return MaterialTags.HELMETS.isTagged(material) || MaterialTags.CHESTPLATES.isTagged(material)
                || MaterialTags.LEGGINGS.isTagged(material) || MaterialTags.BOOTS.isTagged(material)
                || material == Material.ELYTRA;
    }
}
