/*
 * A comment that looks like a keybinding but does not have exactly three
 * fields is skipped; the other keybindings are still shown.
 */

string dump (Gee.Map<string, Gee.ArrayList<Keybinding>> map) {
    var result = new StringBuilder ();
    foreach (var entry in map.entries) {
        foreach (var binding in entry.value) {
            result.append_printf ("%s|%s|%s\n", entry.key, binding.label, binding.spec);
        }
    }
    return result.str;
}

void test_invalid_comments_are_skipped () {
    var config = "## Cat A // Act 1 // <Super> a ##\n" +
                 "## Note // only two fields ##\n" +
                 "## Session // Exit // <Super> q // extra ##\n" +
                 "## Cat B // Act 2 // <Super> b ##\n";
    Test.expect_message (null, LogLevelFlags.LEVEL_WARNING, "*## Note // only two fields ##*");
    Test.expect_message (null, LogLevelFlags.LEVEL_WARNING, "*## Session // Exit // <Super> q // extra ##*");
    try {
        var map = new ConfigParser (config, "").parse ();
        Test.assert_expected_messages ();
        assert_cmpstr (dump (map), CompareOperator.EQ, "Cat A|Act 1|<Super> a\nCat B|Act 2|<Super> b\n");
    } catch (GLib.Error e) {
        error (e.message);
    }
}

void test_invalid_comment_with_prefix () {
    var config = "\"## Cat A // Act 1 // <Super> a ##\n\"## Broken // comment ##\n";
    Test.expect_message (null, LogLevelFlags.LEVEL_WARNING, "*Broken*");
    try {
        var map = new ConfigParser (config, "\"").parse ();
        Test.assert_expected_messages ();
        assert_cmpstr (dump (map), CompareOperator.EQ, "Cat A|Act 1|<Super> a\n");
    } catch (GLib.Error e) {
        error (e.message);
    }
}

int main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/parser/invalid_comments_are_skipped", test_invalid_comments_are_skipped);
    Test.add_func ("/parser/invalid_comment_with_prefix", test_invalid_comment_with_prefix);
    return Test.run ();
}
