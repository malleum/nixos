{pkgs, ...}:
pkgs.writers.writeRustBin "emojify" {}
/*
rust
*/
''
  use std::env;

  // Each entry: (shortcode, &[keywords])
  // Keywords include the shortcode words plus common synonyms/related terms
  static EMOJIS: &[(&str, &[&str])] = &[
    (":smile:", &["smile", "smiling", "happy", "grin", "grinning"]),
    (":laughing:", &["laugh", "laughing", "lol", "haha", "giggle"]),
    (":rofl:", &["rofl", "rolling", "floor", "hilarious"]),
    (":cry:", &["cry", "crying", "sad", "tear", "weep", "sob"]),
    (":joy:", &["joy", "joyful"]),
    (":heart:", &["heart", "love", "loved", "loving", "adore"]),
    (":broken_heart:", &["broken", "heartbreak", "heartbroken", "dumped"]),
    (":fire:", &["fire", "fired", "flame", "flames", "burning", "burn", "hot", "blaze", "lit"]),
    (":snowflake:", &["snow", "snowflake", "cold", "freeze", "freezing", "frozen", "ice", "icy", "winter"]),
    (":sunny:", &["sun", "sunny", "sunshine", "solar"]),
    (":cloud:", &["cloud", "cloudy", "overcast"]),
    (":cloud_with_lightning:", &["lightning", "thunder", "thunderstorm", "storm", "stormy", "bolt", "electric"]),
    (":cloud_with_rain:", &["rain", "raining", "rainy", "drizzle", "wet", "umbrella"]),
    (":snowman:", &["snowman", "snowy"]),
    (":rainbow:", &["rainbow", "colorful", "pride"]),
    (":zap:", &["zap", "fast", "quick", "speed", "flash", "electric", "power"]),
    (":star:", &["star", "stars", "starred", "starry", "celebrity"]),
    (":star2:", &["glowing", "sparkle", "shiny"]),
    (":moon:", &["moon", "lunar", "night"]),
    (":earth_americas:", &["earth", "world", "globe", "planet", "global"]),
    (":ocean:", &["ocean", "sea", "wave", "waves", "surf", "surfing"]),
    (":mount_fuji:", &["mountain", "mount", "peak", "summit", "climb", "hiking", "hike"]),
    (":deciduous_tree:", &["tree", "trees", "forest", "woodland", "nature"]),
    (":rose:", &["rose", "roses", "flower", "flowers", "floral", "bloom", "blossoms"]),
    (":tulip:", &["tulip"]),
    (":four_leaf_clover:", &["clover", "luck", "lucky"]),
    (":mushroom:", &["mushroom", "fungi", "fungus", "shroom"]),
    (":dog:", &["dog", "dogs", "puppy", "pup", "canine", "hound", "pooch"]),
    (":cat:", &["cat", "cats", "kitten", "kitty", "feline"]),
    (":mouse:", &["mouse", "mice", "rat", "rodent"]),
    (":rabbit:", &["rabbit", "bunny", "hare"]),
    (":bear:", &["bear", "bears", "panda"]),
    (":pig:", &["pig", "hog", "swine", "bacon"]),
    (":cow:", &["cow", "bull", "cattle", "beef", "dairy"]),
    (":horse:", &["horse", "horses", "pony", "stallion", "equine", "ride", "riding"]),
    (":wolf:", &["wolf", "wolves"]),
    (":fox_face:", &["fox", "foxes"]),
    (":lion:", &["lion", "lions", "roar"]),
    (":tiger:", &["tiger", "tigers"]),
    (":elephant:", &["elephant", "elephants"]),
    (":monkey:", &["monkey", "ape", "primate"]),
    (":penguin:", &["penguin", "penguins"]),
    (":chicken:", &["chicken", "hen", "chick", "poultry"]),
    (":snake:", &["snake", "serpent", "viper", "reptile"]),
    (":turtle:", &["turtle", "tortoise"]),
    (":fish:", &["fish", "fishing", "fishes", "seafood"]),
    (":shark:", &["shark", "sharks", "predator"]),
    (":whale:", &["whale", "whales"]),
    (":octopus:", &["octopus", "squid"]),
    (":spider:", &["spider", "spiders", "arachnid", "web"]),
    (":bee:", &["bee", "bees", "honey", "buzz", "sting"]),
    (":ant:", &["ant", "ants"]),
    (":butterfly:", &["butterfly", "butterflies"]),
    (":apple:", &["apple", "apples", "fruit"]),
    (":banana:", &["banana", "bananas"]),
    (":cherry:", &["cherry", "cherries"]),
    (":strawberry:", &["strawberry", "strawberries"]),
    (":grapes:", &["grapes", "grape", "vine", "wine"]),
    (":watermelon:", &["watermelon"]),
    (":pizza:", &["pizza", "pie", "pepperoni"]),
    (":hamburger:", &["burger", "hamburger", "cheeseburger"]),
    (":hotdog:", &["hotdog", "sausage"]),
    (":taco:", &["taco", "tacos"]),
    (":sushi:", &["sushi"]),
    (":ramen:", &["ramen", "noodle", "noodles"]),
    (":coffee:", &["coffee", "espresso", "cafe", "latte", "cappuccino", "brew"]),
    (":tea:", &["tea", "chai", "herbal"]),
    (":beer:", &["beer", "ale", "lager", "brew", "drinking"]),
    (":wine_glass:", &["wine", "champagne"]),
    (":cake:", &["cake", "birthday", "dessert", "baking", "bake"]),
    (":cookie:", &["cookie", "cookies"]),
    (":icecream:", &["ice cream", "icecream", "gelato"]),
    (":house:", &["house", "home", "building"]),
    (":car:", &["car", "drive", "driving", "vehicle", "auto"]),
    (":airplane:", &["plane", "airplane", "fly", "flying", "flight", "travel"]),
    (":rocket:", &["rocket", "launch", "space", "spacecraft", "spaceship"]),
    (":train:", &["train", "railway", "rail", "commute"]),
    (":ship:", &["ship", "boat", "sailing", "sail", "cruise"]),
    (":bike:", &["bike", "bicycle", "cycling", "cycle"]),
    (":phone:", &["phone", "call", "calling", "telephone", "ring"]),
    (":computer:", &["computer", "laptop", "pc", "desktop"]),
    (":keyboard:", &["keyboard", "typing", "type"]),
    (":camera:", &["camera", "photo", "photograph", "picture", "pic"]),
    (":book:", &["book", "read", "reading", "novel", "library"]),
    (":pencil:", &["pencil", "write", "writing", "draw", "drawing"]),
    (":scissors:", &["scissors", "cut", "cutting"]),
    (":hammer:", &["hammer", "build", "building", "construction"]),
    (":wrench:", &["wrench", "fix", "fixing", "repair", "tool"]),
    (":money_with_wings:", &["money", "cash", "dollars", "finance", "pay", "payment", "spend"]),
    (":moneybag:", &["moneybag", "rich", "wealth", "profit"]),
    (":trophy:", &["trophy", "award", "prize", "winner", "winning", "win"]),
    (":medal_sports:", &["medal", "gold", "silver", "olympic"]),
    (":soccer:", &["soccer", "football", "goal"]),
    (":basketball:", &["basketball", "hoop", "nba"]),
    (":baseball:", &["baseball", "mlb"]),
    (":tennis:", &["tennis"]),
    (":golf:", &["golf"]),
    (":swimming_man:", &["swim", "swimming", "swimmer", "pool"]),
    (":running:", &["run", "running", "runner", "jog", "jogging", "sprint"]),
    (":weight_lifting:", &["lift", "lifting", "gym", "workout", "exercise", "muscle"]),
    (":clown_face:", &["clown", "clowns", "joker", "silly", "fool"]),
    (":ghost:", &["ghost", "haunt", "haunted", "spooky", "scary", "boo"]),
    (":skull:", &["skull", "dead", "death", "die", "died", "danger"]),
    (":robot:", &["robot", "ai", "android", "bot", "automation"]),
    (":alien:", &["alien", "ufo", "extraterrestrial", "space"]),
    (":crown:", &["crown", "king", "queen", "royal", "royalty", "boss"]),
    (":gem:", &["gem", "diamond", "jewel", "ruby", "sapphire", "crystal"]),
    (":lock:", &["lock", "locked", "secure", "security", "privacy", "private"]),
    (":key:", &["key", "keys", "unlock", "access", "password"]),
    (":bomb:", &["bomb", "explosion", "explode", "detonate", "boom"]),
    (":gun:", &["gun", "shoot", "shooting", "bullet"]),
    (":knife:", &["knife", "blade", "cut", "stab"]),
    (":pill:", &["pill", "medicine", "medication", "drug"]),
    (":hospital:", &["hospital", "doctor", "medical", "clinic", "health"]),
    (":ambulance:", &["ambulance", "emergency"]),
    (":police_car:", &["police", "cop", "arrest", "crime"]),
    (":warning:", &["warning", "danger", "alert", "caution"]),
    (":no_entry:", &["stop", "blocked", "denied", "forbidden", "ban", "banned"]),
    (":white_check_mark:", &["check", "done", "complete", "completed", "yes", "correct"]),
    (":x:", &["wrong", "incorrect", "error", "fail", "failed", "no", "nope"]),
    (":100:", &["hundred", "perfect", "percent", "100"]),
    (":tada:", &["party", "celebration", "celebrate", "congrats", "congratulations", "tada", "hooray"]),
    (":confetti_ball:", &["confetti"]),
    (":sparkles:", &["sparkle", "magic", "magical", "wow", "amazing", "glitter"]),
    (":muscle:", &["muscle", "strong", "strength", "power", "flex"]),
    (":wave:", &["wave", "waving", "goodbye", "hello", "hi", "bye"]),
    (":pray:", &["pray", "prayer", "please", "thanks", "thank", "grateful", "gratitude"]),
    (":clap:", &["clap", "clapping", "applause", "bravo"]),
    (":thumbsup:", &["good", "great", "nice", "approve", "thumbs", "up", "like", "yes"]),
    (":thumbsdown:", &["bad", "dislike", "disapprove", "thumbs", "down"]),
    (":point_right:", &["point", "pointing", "right", "this", "here"]),
    (":eyes:", &["eye", "eyes", "watch", "watching", "look", "looking", "see", "seeing"]),
    (":brain:", &["brain", "think", "thinking", "thought", "smart", "intelligence", "idea"]),
    (":tongue:", &["tongue", "taste", "lick", "yummy"]),
    (":ear:", &["ear", "hear", "hearing", "listen", "listening"]),
    (":nose:", &["nose", "smell", "smelling"]),
    (":sleeping:", &["sleep", "sleeping", "tired", "rest", "nap", "dream", "zzz"]),
    (":dizzy_face:", &["dizzy", "confused", "confusing", "spin"]),
    (":exploding_head:", &["mind blown", "mindblown", "shocked", "shock", "shocking", "crazy"]),
    (":partying_face:", &["party", "partying", "celebration"]),
    (":nerd_face:", &["nerd", "geek", "smart", "study", "studying"]),
    (":sunglasses:", &["cool", "sunglasses", "awesome", "shade"]),
    (":rage:", &["rage", "angry", "anger", "furious", "fury", "mad"]),
    (":weary:", &["weary", "tired", "exhausted", "weariness"]),
    (":worried:", &["worry", "worried", "anxious", "anxiety", "nervous"]),
    (":money_mouth_face:", &["money", "greedy", "greed", "profit"]),
    (":thinking:", &["think", "thinking", "thought", "wonder", "wondering", "hmm", "ponder"]),
    (":shrug:", &["shrug", "dunno", "whatever", "idk", "unsure"]),
    (":facepalm:", &["facepalm", "doh", "oops", "mistake", "embarrassing"]),
    (":construction:", &["construction", "building", "work", "progress", "wip"]),
    (":recycle:", &["recycle", "recycling", "eco", "green", "environment"]),
    (":seedling:", &["plant", "plants", "grow", "growing", "seedling", "sprout"]),
    (":tornado:", &["tornado", "twister", "hurricane", "cyclone", "wind"]),
    (":volcano:", &["volcano", "volcanic", "eruption", "lava"]),
    (":comet:", &["comet", "meteor", "asteroid"]),
    (":crystal_ball:", &["crystal", "ball", "predict", "future", "fortune", "psychic"]),

        (":grinning:", &["grin", "grinning", "cheerful"]),
    (":smiley:", &["smiley", "joyful", "bright"]),
    (":blush:", &["blush", "blushing", "shy"]),
    (":wink:", &["wink", "winking"]),
    (":heart_eyes:", &["heart eyes", "infatuated", "love struck"]),
    (":kissing_heart:", &["kiss", "kissing", "affection"]),
    (":thinking_face:", &["thinking face", "considering"]),
    (":neutral_face:", &["neutral", "meh"]),
    (":expressionless:", &["expressionless", "blank"]),
    (":rolling_eyes:", &["eyeroll", "rolling eyes", "sarcasm"]),
    (":smirk:", &["smirk", "smug"]),
    (":hugging_face:", &["hug", "hugging"]),
    (":face_with_raised_eyebrow:", &["skeptical", "raised eyebrow"]),
    (":face_with_hand_over_mouth:", &["gasp", "oops"]),
    (":shushing_face:", &["shush", "quiet", "secret"]),
    (":sleepy:", &["sleepy", "drowsy"]),
    (":drooling_face:", &["drool", "drooling", "hungry"]),
    (":nauseated_face:", &["nausea", "sick", "vomit"]),
    (":mask:", &["mask", "ill", "surgery"]),
    (":thermometer_face:", &["fever", "temperature"]),
    (":exploding_head:", &["mind blown", "mind blown face"]),

    (":handshake:", &["handshake", "deal", "agreement"]),
    (":fist:", &["fist", "punch"]),
    (":v:", &["victory", "peace sign"]),
    (":metal:", &["rock on", "metal hand"]),
    (":ok_hand:", &["ok", "okay", "fine"]),
    (":raised_hands:", &["raised hands", "hallelujah"]),
    (":writing_hand:", &["writing hand", "note taking"]),

    (":microphone:", &["microphone", "sing", "singing"]),
    (":guitar:", &["guitar", "music", "musician"]),
    (":headphones:", &["headphones", "listen music"]),
    (":drum:", &["drum", "drums"]),
    (":violin:", &["violin"]),
    (":musical_note:", &["note", "music note"]),
    (":musical_score:", &["sheet music"]),

    (":video_game:", &["video game", "gaming", "gamer"]),
    (":joystick:", &["joystick"]),
    (":game_die:", &["dice", "die", "roll"]),
    (":chess_pawn:", &["chess", "pawn"]),

    (":satellite:", &["satellite", "orbit"]),
    (":satellite_antenna:", &["antenna", "signal"]),
    (":battery:", &["battery", "charge", "charging"]),
    (":electric_plug:", &["plug", "electricity"]),
    (":bulb:", &["bulb", "idea", "lightbulb"]),
    (":mag:", &["magnify", "search"]),
    (":floppy_disk:", &["floppy", "save"]),
    (":cd:", &["cd", "disk"]),
    (":dvd:", &["dvd"]),
    (":minidisc:", &["minidisc"]),

    (":toolbox:", &["toolbox", "tools"]),
    (":gear:", &["gear", "settings", "config"]),
    (":chains:", &["chain", "chained"]),
    (":mag_right:", &["search right"]),
    (":mag_left:", &["search left"]),

    (":shopping_cart:", &["shopping", "cart"]),
    (":credit_card:", &["credit card", "card payment"]),
    (":receipt:", &["receipt", "invoice"]),
    (":chart_with_upwards_trend:", &["growth", "trend up", "increase"]),
    (":chart_with_downwards_trend:", &["decline", "trend down", "decrease"]),
    (":bar_chart:", &["bar chart", "statistics"]),
    (":clipboard:", &["clipboard", "notes"]),
    (":file_folder:", &["folder", "directory"]),
    (":open_file_folder:", &["open folder"]),
    (":link:", &["link", "url"]),
    (":paperclip:", &["paperclip", "attachment"]),

    (":calendar:", &["calendar", "date"]),
    (":alarm_clock:", &["alarm", "alarm clock"]),
    (":stopwatch:", &["stopwatch", "timer"]),
    (":hourglass:", &["hourglass", "waiting"]),

    (":compass:", &["compass", "direction"]),
    (":map:", &["map"]),
    (":camping:", &["camping", "camp"]),
    (":tent:", &["tent"]),
    (":mountain_snow:", &["snowy mountain"]),
    (":desert:", &["desert"]),
    (":island:", &["island"]),
    (":cityscape:", &["city", "cityscape"]),
    (":night_with_stars:", &["night sky"]),

    (":red_car:", &["red car"]),
    (":taxi:", &["taxi"]),
    (":bus:", &["bus"]),
    (":truck:", &["truck"]),
    (":motorcycle:", &["motorcycle", "bike engine"]),
    (":helicopter:", &["helicopter"]),
    (":parachute:", &["parachute"]),
    (":fuelpump:", &["fuel", "gas", "gasoline"]),

    (":anchor:", &["anchor"]),
    (":fishing_pole_and_fish:", &["fishing rod"]),
    (":sailboat:", &["sailboat"]),

    (":crossed_swords:", &["battle", "fight"]),
    (":shield:", &["shield", "defense"]),
    (":bow_and_arrow:", &["archery"]),
    (":axe:", &["axe"]),
    (":dagger:", &["dagger"]),

    (":coffin:", &["coffin"]),
    (":urn:", &["urn"]),
    (":latin_cross:", &["cross"]),
    (":yin_yang:", &["yin yang"]),
    (":peace_symbol:", &["peace symbol"]),
    (":infinity:", &["infinity", "forever"]),

  ];

  fn stem(word: &str) -> &str {
    // Very lightweight suffix stripping
    let w = word;
    if w.len() > 5 {
      if w.ends_with("ing") { return &w[..w.len()-3]; }
      if w.ends_with("tion") { return &w[..w.len()-4]; }
    }
    if w.len() > 4 {
      if w.ends_with("ed") { return &w[..w.len()-2]; }
      if w.ends_with("er") { return &w[..w.len()-2]; }
      if w.ends_with("ly") { return &w[..w.len()-2]; }
      if w.ends_with("es") { return &w[..w.len()-2]; }
    }
    if w.len() > 3 {
      if w.ends_with("s") { return &w[..w.len()-1]; }
    }
    w
  }

  fn matches(input_word: &str, keyword: &str) -> bool {
    // exact
    if input_word == keyword { return true; }
    // input contains keyword
    if input_word.contains(keyword) { return true; }
    // keyword contains input
    if keyword.contains(input_word) { return true; }
    // stemmed forms
    let s1 = stem(input_word);
    let s2 = stem(keyword);
    s1 == s2 || s1 == keyword || s2 == input_word
  }

  fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
      eprintln!("Usage: emojify <sentence>");
      std::process::exit(1);
    }
    let sentence = args[1..].join(" ").to_lowercase();
    let words: Vec<&str> = sentence
      .split(|c: char| !c.is_alphanumeric())
      .filter(|w| !w.is_empty())
      .collect();

    let mut best_match_shortcode: Option<&str> = None;

    for word in &words {
      for (shortcode, keywords) in EMOJIS {
        for kw in *keywords {
          if matches(word, kw) {
            best_match_shortcode = Some(shortcode);
            break; // Found a match for this word, break from keywords loop
          }
        }
        if best_match_shortcode.is_some() {
          break; // Found a match for this word, break from EMOJIS loop
        }
      }
      if best_match_shortcode.is_some() {
        break; // Found a match for some word, break from words loop
      }
    }

    if let Some(shortcode) = best_match_shortcode {
      println!("{}", shortcode);
    } else {
      println!("(no matches)");
    }
  }
''
