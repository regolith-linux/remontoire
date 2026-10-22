/*
 * A line that is not valid UTF-8 (for example from a Latin-1 config file) is
 * read as Latin-1 and shown, instead of as an empty label; valid UTF-8 lines
 * are kept as they are.
 */

void test_latin1_line_is_converted () {
    // "Fenster schließen" in Latin-1, between two valid UTF-8 lines.
    var sharp_s = "%c".printf (0xdf);
    var config = "## Arrows // Move // <Super> ↑ ↓ ##\n" +
                 "## Fenster // Fenster schlie" + sharp_s + "en // <Super> " + sharp_s + " ##\n" +
                 "## Caf\u00e9 // Na\u00efve // <Super> \u00e9 ##\n";
    assert (!config.validate ());
    try {
        var map = new ConfigParser (config, "").parse ();
        assert_cmpstr (map["Fenster"][0].label, CompareOperator.EQ, "Fenster schließen");
        assert_cmpstr (map["Fenster"][0].spec, CompareOperator.EQ, "<Super> ß");
        assert_cmpstr (map["Arrows"][0].spec, CompareOperator.EQ, "<Super> ↑ ↓");
        assert_cmpstr (map["Café"][0].label, CompareOperator.EQ, "Naïve");
    } catch (GLib.Error e) {
        error (e.message);
    }
}

int main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/parser/latin1_line_is_converted", test_latin1_line_is_converted);
    return Test.run ();
}
