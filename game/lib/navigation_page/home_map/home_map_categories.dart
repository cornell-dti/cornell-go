/// Home map category definitions.
///
/// Update [homeMapCategories] to change:
/// - the chip label + icon
/// - the pin icon asset families used by the map markers
///
/// Category indices used throughout the map correspond to this list order.
class HomeMapCategory {
  final String label;
  final String chipIconAsset;

  /// Base name for unselected pins without `_color.svg` suffix
  final String pinBaseAsset;

  /// Base name for selected pins without `_color.svg` suffix
  final String selectedPinBaseAsset;

  const HomeMapCategory({
    required this.label,
    required this.chipIconAsset,
    required this.pinBaseAsset,
    required this.selectedPinBaseAsset,
  });
}

const homeMapCategories = <HomeMapCategory>[
  HomeMapCategory(
    label: 'Food',
    chipIconAsset: 'assets/icons/burger.svg',
    pinBaseAsset: 'burger_pin',
    selectedPinBaseAsset: 'selected_pin',
  ),
  HomeMapCategory(
    label: 'Concerts',
    chipIconAsset: 'assets/icons/mic.svg',
    pinBaseAsset: 'mic_pin',
    selectedPinBaseAsset: 'selected_mic_pin',
  ),
  HomeMapCategory(
    label: 'Speakers',
    chipIconAsset: 'assets/icons/speaker.svg',
    pinBaseAsset: 'speaker_pin',
    selectedPinBaseAsset: 'selected_speaker_pin',
  ),
  HomeMapCategory(
    label: 'Fundraisers',
    chipIconAsset: 'assets/icons/fund.svg',
    pinBaseAsset: 'fund_pin',
    selectedPinBaseAsset: 'selected_fund_pin',
  ),
];
