/// The one list of feature modules. The shell holds the only such list.
///
/// One entry per feature, in tab order:
///   feature_library    tab "library"
///   feature_words      tab "words"
///   feature_map        tab "map"
///   feature_speaking   tab "speak"
///   feature_profile    tab "me"
/// The two features that are not tabs follow:
///   feature_story      opened by StoryRoute
///   feature_review     opened by ReviewRoute and LevelCheckRoute
///
/// Empty until order 26. Order 26 types it as the list of FeatureModule
/// (page 12, section 3) once order 02 has written that type.
const List<Object> modules = <Object>[];
