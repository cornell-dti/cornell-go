import 'package:flutter/material.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:game/model/user_model.dart';
import 'package:game/profile/build_a_bear/bear_preview.dart';
import 'package:provider/provider.dart';
import 'dart:async';

/// Build-a-Bear page for avatar customization.
///
/// Displays a live bear preview on top and a tabbed item grid (Eyes, Mouth,
/// Color, Accessories) on the bottom. Items are loaded via WebSocket and can
/// be previewed, purchased, equipped, or unequipped.
class BuildABearPage extends StatefulWidget {
  const BuildABearPage({Key? key}) : super(key: key);

  @override
  State<BuildABearPage> createState() => _BuildABearPageState();
}

enum _BuildABearTab { eyes, mouth, color, accessories }

class _BuildABearPageState extends State<BuildABearPage> {
  _BuildABearTab _selectedTab = _BuildABearTab.eyes;

  /// Bear items loaded from the backend via WebSocket.
  /// Items are filtered into separate lists for each tab.
  List<BearItemDto> _colorItems = [];
  List<BearItemDto> _eyeItems = [];
  List<BearItemDto> _mouthItems = [];
  List<BearItemDto> _accessoryItems = [];

  /// All items indexed by ID for O(1) lookups.
  Map<String, BearItemDto> _itemById = {};

  /// Whether the initial bear-item fetch is still in progress.
  bool _isLoading = true;

  /// Currently equipped item IDs keyed by slot.
  Map<BearSlotDto, String?> _equippedBySlot = {};

  /// Items currently displayed on the bear preview.
  /// Starts as a copy of equipped items, updated when user taps an item.
  Map<BearSlotDto, String?> _displayedBySlot = {};

  /// ID of the currently selected (tapped) item in the grid, or null.
  String? _selectedItemId;

  /// IDs of items the user owns (from inventory).
  Set<String> _ownedItemIds = {};

  /// Subscription to the bear-items catalog stream (all available items).
  StreamSubscription<UpdateBearItemsDataDto>? _bearItemsSub;

  /// Subscription to the user's equipped-loadout stream.
  StreamSubscription<UpdateUserBearLoadoutDataDto>? _loadoutSub;

  /// Subscription to the user's inventory stream (owned items).
  StreamSubscription<UpdateUserInventoryDataDto>? _inventorySub;

  @override
  void initState() {
    super.initState();
    // Defer API access until we have a BuildContext.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestBearItems();
    });
  }

  @override
  void dispose() {
    _bearItemsSub?.cancel();
    _loadoutSub?.cancel();
    _inventorySub?.cancel();
    super.dispose();
  }

  /// Subscribes to bear-item, loadout, and inventory streams, then requests
  /// the initial data from the server. Called once from [initState].
  void _requestBearItems() {
    final apiClient = context.read<ApiClient>();
    final server = apiClient.serverApi;
    if (server == null) {
      // Not connected yet; leave the UI in loading/empty state.
      return;
    }

    // Listen for updates from the server exactly once per page lifetime.
    _bearItemsSub ??=
        apiClient.clientApi.updateBearItemsDataStream.listen((update) {
      setState(() {
        final grouped = <BearSlotDto, List<BearItemDto>>{};
        for (final item in update.items) {
          (grouped[item.slot] ??= []).add(item);
        }
        for (final list in grouped.values) {
          list.sort((a, b) => a.cost.compareTo(b.cost));
        }
        _colorItems = grouped[BearSlotDto.COLOR] ?? [];
        _eyeItems = grouped[BearSlotDto.EYES] ?? [];
        _mouthItems = grouped[BearSlotDto.MOUTH] ?? [];
        _accessoryItems = grouped[BearSlotDto.ACCESSORY] ?? [];
        _itemById = {for (final item in update.items) item.id: item};
        _isLoading = false;
      });
    });

    // Listen for user bear loadout updates (equipped items).
    _loadoutSub ??=
        apiClient.clientApi.updateUserBearLoadoutDataStream.listen((loadout) {
      setState(() {
        _equippedBySlot = {
          for (final e in loadout.equipped) e.slot: e.itemId,
        };
        _displayedBySlot = Map.from(_equippedBySlot);
        _selectedItemId = null;
      });
    });

    // Listen for user inventory updates (owned items).
    _inventorySub ??=
        apiClient.clientApi.updateUserInventoryDataStream.listen((inv) {
      setState(() {
        _ownedItemIds = inv.items.map((i) => i.id).toSet();
      });
    });

    // Request all bear items (all slots); the service will return COLOR, EYES, etc.
    server.requestBearItems(RequestBearItemsDto());

    // Request the user's current equipped loadout.
    server.requestUserBearLoadout(RequestUserBearLoadoutDto());

    // Request the user's inventory (owned items).
    server.requestUserInventory(RequestUserInventoryDto());
  }

  /// Builds the page layout: a top section with the bear preview over a
  /// background image, and a bottom section with the tab bar and item grid.
  /// A floating action button appears when a non-equipped item is selected.
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    final topPadding = MediaQuery.of(context).padding.top;

    final topSectionHeight = screenHeight * 0.40;
    final bearWidth = screenWidth * 0.45;
    final bearHeight = bearWidth * (593 / 429);

    // Determine whether to show the action button (purchase, equip, or unequip)
    final isSelectedEquipped = _isSelectedItemEquipped();
    final showActionButton =
        _selectedItemId != null && !isSelectedEquipped;
    final isSelectedOwned =
        _selectedItemId != null && _ownedItemIds.contains(_selectedItemId);

    // Show unequip button when an equipped accessory is selected
    final showUnequipButton = _selectedItemId != null &&
        isSelectedEquipped &&
        _selectedTab == _BuildABearTab.accessories &&
        _equippedBySlot[BearSlotDto.ACCESSORY] != null;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5EA),
      body: Stack(
        children: [
          Column(
        children: [
          // Top section: background aligned to top, bear + back button overlay
          SizedBox(
            height: topSectionHeight,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              alignment: Alignment.topCenter,
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/bearbackground.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
                // Bear preview (shared widget)
                Positioned(
                  top: topSectionHeight * 0.40,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Center(
                    child: BearPreview(
                      bearWidth: bearWidth,
                      bearHeight: bearHeight,
                      itemForSlot: _displayedItemForSlot,
                    ),
                  ),
                ),
                Positioned(
                  top: topPadding,
                  left: 0,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                // Points badge in top right
                Positioned(
                  top: topPadding + 8,
                  right: screenWidth * 0.04,
                  child: Consumer<UserModel>(
                    builder: (context, userModel, _) {
                      final coins = userModel.userData?.coins;
                      if (coins == null) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 2),
                        clipBehavior: Clip.antiAlias,
                        decoration: ShapeDecoration(
                          color: const Color(0xFFC17E19),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              width: 2,
                              strokeAlign: BorderSide.strokeAlignCenter,
                              color: const Color(0xFFFFC737),
                            ),
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/images/pawcoin.png',
                              width: 16,
                              height: 16,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$coins',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.035,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Bottom section: tab bar + color grid
          Expanded(
            child: Container(
              color: const Color(0xFFF5F0E8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Navbar: Eyes, Mouth, Color, Accessories (evenly spaced, white background)
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                            child: _buildNavTab('Eyes', _BuildABearTab.eyes)),
                        Expanded(
                            child: _buildNavTab('Mouth', _BuildABearTab.mouth)),
                        Expanded(
                            child: _buildNavTab('Color', _BuildABearTab.color)),
                        Expanded(
                            child: _buildNavTab(
                                'Accessories', _BuildABearTab.accessories)),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // 3x3 item grid (scrollable to prevent overflow)
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.06,
                        vertical: 12,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          const spacing = 12.0;
                          final cellWidth =
                              (constraints.maxWidth - spacing * 2) / 3;
                          final cellHeight = cellWidth * 1.1;
                          final List<BearItemDto> items;
                          switch (_selectedTab) {
                            case _BuildABearTab.color:
                              items = _colorItems;
                              break;
                            case _BuildABearTab.eyes:
                              items = _eyeItems;
                              break;
                            case _BuildABearTab.mouth:
                              items = _mouthItems;
                              break;
                            case _BuildABearTab.accessories:
                              items = _accessoryItems;
                              break;
                          }

                          if (_isLoading) {
                            return SizedBox(
                              height: cellHeight * 3 + spacing * 2,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          if (items.isEmpty) {
                            return SizedBox(
                              height: cellHeight * 3 + spacing * 2,
                              child: const Center(
                                child: Text(
                                  'No items available yet.',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }

                          final rows = (items.length / 3).ceil();
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (var row = 0; row < rows; row++)
                                Padding(
                                  padding: EdgeInsets.only(
                                    bottom: row < rows - 1 ? spacing : 0,
                                  ),
                                  child: Row(
                                    children: [
                                      for (var col = 0; col < 3; col++) ...[
                                        if (col > 0) SizedBox(width: spacing),
                                        if (row * 3 + col < items.length)
                                          SizedBox(
                                            width: cellWidth,
                                            height: cellHeight,
                                            child: _buildItemCell(
                                              item: items[row * 3 + col],
                                              cellSize: cellWidth,
                                            ),
                                          )
                                        else
                                          const Expanded(
                                              child: SizedBox.shrink()),
                                      ],
                                    ],
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      if (showActionButton)
        Positioned(
          bottom: screenHeight * 0.0025,
          left: screenWidth * 0.06,
          right: screenWidth * 0.06,
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  final item = _getSelectedItem();
                  if (item == null) return;
                  if (isSelectedOwned) {
                    _showEquipDialog(item);
                  } else {
                    _showPurchaseDialog(item);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelectedOwned
                      ? const Color(0xFF8B4513)
                      : const Color(0xFFC85C5C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isSelectedOwned ? 'Equip Item' : 'Purchase Item',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      if (showUnequipButton)
        Positioned(
          bottom: screenHeight * 0.0025,
          left: screenWidth * 0.06,
          right: screenWidth * 0.06,
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  _showUnequipDialog();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B4513),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Unequip Accessory',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
      ),
    );
  }

  /// Check if the currently selected item is the equipped one for its slot.
  bool _isSelectedItemEquipped() {
    if (_selectedItemId == null) return true;
    final item = _itemById[_selectedItemId];
    if (item == null) return true;
    return _equippedBySlot[item.slot] == item.id;
  }

  /// Returns the currently selected [BearItemDto], or null.
  BearItemDto? _getSelectedItem() {
    if (_selectedItemId == null) return null;
    return _itemById[_selectedItemId];
  }

  /// Shared confirmation dialog used by purchase, equip, and unequip flows.
  ///
  /// [preview] is the widget shown at the top of the dialog (e.g. item image
  /// or an icon). [message] is the prompt text. [actionLabel] and
  /// [actionColor] style the confirm button. [onConfirm] is called when the
  /// user taps confirm and receives the dialog's [BuildContext] so it can
  /// close the dialog after the async operation completes.
  void _showConfirmationDialog({
    required Widget preview,
    required String message,
    required String actionLabel,
    required Color actionColor,
    required Future<void> Function(BuildContext dialogContext) onConfirm,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: const Color(0xFFFFF5EA),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF8B4513),
                          width: 2,
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: preview,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: OutlinedButton(
                              onPressed: isLoading
                                  ? null
                                  : () => Navigator.pop(dialogContext),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF8B4513),
                                side: const BorderSide(
                                  color: Color(0xFF8B4513),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(23),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton(
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                      setDialogState(
                                          () => isLoading = true);
                                      await onConfirm(dialogContext);
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: actionColor,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    actionColor.withOpacity(0.6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(23),
                                ),
                                elevation: 0,
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      actionLabel,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Shows a confirmation dialog for purchasing [item].
  ///
  /// On confirm, delegates to [_handlePurchase] which sends the purchase
  /// request, auto-equips on success, and refreshes the coin balance.
  void _showPurchaseDialog(BearItemDto item) {
    _showConfirmationDialog(
      preview: Image.asset(
        'assets/${item.assetKey}.png',
        fit: BoxFit.contain,
      ),
      message:
          'Would you like to purchase this item for ${item.cost} coins?',
      actionLabel: 'Purchase',
      actionColor: const Color(0xFFC85C5C),
      onConfirm: (dialogContext) => _handlePurchase(item, dialogContext),
    );
  }

  /// Executes the purchase request for [item], auto-equips on success,
  /// refreshes the coin balance, and closes the [dialogContext] dialog.
  /// Shows a snackbar on insufficient funds.
  Future<void> _handlePurchase(
      BearItemDto item, BuildContext dialogContext) async {
    final apiClient = context.read<ApiClient>();
    final server = apiClient.serverApi;
    if (server == null) return;

    // Send purchase request
    server.purchaseBearItem(PurchaseBearItemDto(itemId: item.id));

    // Wait for the purchase result from the server
    final result =
        await apiClient.clientApi.updatePurchaseResultStream.first;

    if (!mounted) return;

    if (result.success) {
      // Equip the newly purchased item
      server.equipBearItem(EquipBearItemDto(
        slot: item.slot,
        itemId: item.id,
      ));

      // Refresh user data so coin balance updates in the UI
      server.requestUserData(RequestUserDataDto());

      // Close the dialog
      if (Navigator.canPop(dialogContext)) {
        Navigator.pop(dialogContext);
      }

      // Reset selection (loadout listener will also reset via the equip response)
      setState(() {
        _selectedItemId = null;
        _displayedBySlot = Map.from(_equippedBySlot);
      });
    } else {
      // Close the dialog
      if (Navigator.canPop(dialogContext)) {
        Navigator.pop(dialogContext);
      }

      // Show failure message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Not enough coins to purchase this item.',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: Color(0xFFC85C5C),
          ),
        );
      }
    }
  }

  /// Shows a confirmation dialog for equipping an already-owned [item].
  ///
  /// On confirm, delegates to [_handleEquip] which sends the equip request
  /// and lets the loadout listener update the UI.
  void _showEquipDialog(BearItemDto item) {
    _showConfirmationDialog(
      preview: Image.asset(
        'assets/${item.assetKey}.png',
        fit: BoxFit.contain,
      ),
      message: 'Would you like to equip this item?',
      actionLabel: 'Equip',
      actionColor: const Color(0xFF8B4513),
      onConfirm: (dialogContext) => _handleEquip(item, dialogContext),
    );
  }

  /// Sends the equip request for [item] and closes the [dialogContext] dialog.
  /// The loadout stream listener handles UI updates.
  Future<void> _handleEquip(
      BearItemDto item, BuildContext dialogContext) async {
    final apiClient = context.read<ApiClient>();
    final server = apiClient.serverApi;
    if (server == null) return;

    // Send equip request — the loadout listener will update the UI
    server.equipBearItem(EquipBearItemDto(
      slot: item.slot,
      itemId: item.id,
    ));

    // Close the dialog
    if (Navigator.canPop(dialogContext)) {
      Navigator.pop(dialogContext);
    }

    // Reset selection (loadout listener will also refresh via the equip response)
    setState(() {
      _selectedItemId = null;
      _displayedBySlot = Map.from(_equippedBySlot);
    });
  }

  /// Shows a confirmation dialog for unequipping the current accessory.
  ///
  /// On confirm, delegates to [_handleUnequip] which sends an equip request
  /// with no item ID to clear the accessory slot.
  void _showUnequipDialog() {
    _showConfirmationDialog(
      preview: const Icon(
        Icons.remove_circle_outline,
        size: 64,
        color: Color(0xFF8B4513),
      ),
      message: 'Would you like to remove the current accessory?',
      actionLabel: 'Unequip',
      actionColor: const Color(0xFF8B4513),
      onConfirm: (dialogContext) => _handleUnequip(dialogContext),
    );
  }

  /// Sends an equip request with no item ID to clear the accessory slot,
  /// then closes the [dialogContext] dialog. The loadout stream listener
  /// handles UI updates.
  Future<void> _handleUnequip(BuildContext dialogContext) async {
    final apiClient = context.read<ApiClient>();
    final server = apiClient.serverApi;
    if (server == null) return;

    // Send equip request with no itemId to unequip the accessory slot
    server.equipBearItem(EquipBearItemDto(
      slot: BearSlotDto.ACCESSORY,
    ));

    // Close the dialog
    if (Navigator.canPop(dialogContext)) {
      Navigator.pop(dialogContext);
    }

    // Reset selection (loadout listener will also refresh via the equip response)
    setState(() {
      _selectedItemId = null;
      _displayedBySlot = Map.from(_equippedBySlot);
    });
  }

  /// Look up the equipped [BearItemDto] for a given [slot],
  /// returning `null` when nothing is equipped or items haven't loaded yet.
  BearItemDto? _equippedItemForSlot(BearSlotDto slot) {
    final itemId = _equippedBySlot[slot];
    if (itemId == null) return null;
    final List<BearItemDto> items;
    switch (slot) {
      case BearSlotDto.COLOR:
        items = _colorItems;
        break;
      case BearSlotDto.EYES:
        items = _eyeItems;
        break;
      case BearSlotDto.MOUTH:
        items = _mouthItems;
        break;
      case BearSlotDto.ACCESSORY:
        items = _accessoryItems;
        break;
    }
    try {
      return items.firstWhere((i) => i.id == itemId);
    } catch (_) {
      return null;
    }
  }

  /// Look up the displayed [BearItemDto] for a given [slot].
  /// Uses the "displayed" map which may differ from equipped when
  /// the user taps an item to preview it.
  BearItemDto? _displayedItemForSlot(BearSlotDto slot) {
    final itemId = _displayedBySlot[slot];
    if (itemId == null) return null;
    final List<BearItemDto> items;
    switch (slot) {
      case BearSlotDto.COLOR:
        items = _colorItems;
        break;
      case BearSlotDto.EYES:
        items = _eyeItems;
        break;
      case BearSlotDto.MOUTH:
        items = _mouthItems;
        break;
      case BearSlotDto.ACCESSORY:
        items = _accessoryItems;
        break;
    }
    try {
      return items.firstWhere((i) => i.id == itemId);
    } catch (_) {
      return null;
    }
  }

  static const Color _navSelectedColor = Color(0xFF8C473C);

  /// Builds a single tab button in the category nav bar.
  ///
  /// [label] is the display text and [tab] is the enum value it activates.
  /// Tapping resets the selection and displayed preview back to equipped items.
  Widget _buildNavTab(String label, _BuildABearTab tab) {
    final isSelected = _selectedTab == tab;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = tab;
          _selectedItemId = null;
          _displayedBySlot = Map.from(_equippedBySlot);
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
                  color: isSelected ? _navSelectedColor : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a single grid cell displaying [item]'s thumbnail and status label.
  ///
  /// [cellSize] controls the thumbnail dimensions. The cell is highlighted
  /// when it is the actively selected item or, if nothing is selected, when
  /// it is the currently equipped item for its slot.
  Widget _buildItemCell({
    required BearItemDto item,
    required double cellSize,
  }) {
    final isEquipped = _equippedBySlot[item.slot] == item.id;
    final isHighlighted = _selectedItemId != null
        ? _selectedItemId == item.id
        : isEquipped;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedItemId = item.id;
          _displayedBySlot[item.slot] = item.id;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isHighlighted ? const Color(0xFF8B4513) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Bear item thumbnail
            SizedBox(
              width: cellSize * 0.5,
              height: cellSize * 0.5,
              child: Image.asset(
                'assets/${item.assetKey}.png',
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 4),
            _buildItemLabel(item, isEquipped),
          ],
        ),
      ),
    );
  }

  /// Builds the label widget below an item thumbnail.
  /// Priority: equipped (CURRENT) > owned (OWNED) > cost.
  Widget _buildItemLabel(BearItemDto item, bool isEquipped) {
    final isOwned = _ownedItemIds.contains(item.id);

    if (isEquipped) {
      return Text(
        'CURRENT',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF8B4513),
        ),
      );
    }
    if (isOwned) {
      return Text(
        'OWNED',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF8B4513),
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/pawcoin.png',
          width: 14,
          height: 14,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 2),
        Text(
          '${item.cost} COINS',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

