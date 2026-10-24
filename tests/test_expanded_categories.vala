/*
 * The saved list of expanded categories gives back the same category names,
 * including names with commas.
 */

void test_round_trip () {
    var categories = new Gee.HashSet<string>();
    categories.add ("Windows, Tabs");
    categories.add ("Launch");
    categories.add ("100% Fun");
    categories.add ("Odd %2C name");

    var saved = Helper.join_categories (categories);
    var loaded = Helper.split_categories (saved);
    assert (loaded.size == 4);
    foreach (var category in categories) {
        assert (category in loaded);
    }
}

void test_existing_settings () {
    // Values saved by earlier versions, including the default "".
    var loaded = Helper.split_categories (",Other,Navigate,");
    assert (loaded.size == 2);
    assert ("Other" in loaded);
    assert ("Navigate" in loaded);
    assert (Helper.split_categories ("").size == 0);
}

int main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/categories/round_trip", test_round_trip);
    Test.add_func ("/categories/existing_settings", test_existing_settings);
    return Test.run ();
}
