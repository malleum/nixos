fn main() {
    run_cli(
        "duod",
        "Duod time: the fraction of the local day in base 12, to five places.\n\
         Noon is 60000; digits ten and eleven are χ and ε (x/e also read).",
        "60000",
        format_duod,
        parse_duod,
        // Historical HH:MM:SS:NS form: the fourth field is nanoseconds.
        |ns| ns / 1_000_000,
    );
}
