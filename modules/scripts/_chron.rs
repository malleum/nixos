fn main() {
    run_cli(
        "chron",
        "Chron time: the local day in hundredths (1 chron = 14.4 minutes),\n\
         to five places as DD.D DD. Noon is 50.0 00.",
        "50.0 00",
        format_chron,
        parse_chron,
        // Historical HH:MM:SS:T form (date +%1N): the fourth field is tenths.
        |tenths| tenths * 100,
    );
}
