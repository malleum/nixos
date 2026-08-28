# Qalculate Custom Units

This document explains the custom units defined in `qalculate_units.xml` for use with `qalc` and `rofi-calc`.

## 1. Metric / Dozenal Day Fractions

| Unit Name | Abbreviation | Definition | Description |
| :--- | :--- | :--- | :--- |
| **Chron** | `ch` | 0.01 days | $1/100$ of a day. Exactly $14.4$ minutes. Metric prefixes allowed (e.g. `kilochron`). |
| **Duod** | `duod` | 1 day | A full day, intended to be parsed into dozenal fractions by appending `to base 12`. |

---

## 2. The Primel System
Primel is a "day-gravity-water" coherent metrology system utilizing dozenal (base-12) scaling. The base units are defined as follows:

| Quantitel (Unit) | Abbrev | Colloquial | Definition / Derivation | Approximate Value |
| :--- | :--- | :--- | :--- | :--- |
| **Timel** | `tml` | vibe (`vb`) | $\frac{1}{12^6}$ of a mean solar day | $0.0289$ seconds |
| **Lengthel**| `lgl` | (none) | The distance an object falls in 1 timel under standard Earth gravity ($g \times \text{timel}^2$) | $8.21$ millimeters |
| **Massel**  | `msl` | (none) | The mass of a cubic lengthel of water at maximum density | $0.552$ grams |

*Note: All Primel base units are also registered with the formal `⚀` branding prefix (e.g., `⚀tml`).*

### Primel Powers and Prefixes
Qalculate's parser aggressively splits unfamiliar prefixes, so all 12 powers of the Primel units have been explicitly registered. 
We support both the formal Unicode abbreviations (`↑` for positive powers, `↓` for negative powers) and the official ASCII fallbacks (`q` for positive powers (from _qua_), `c` for negative powers (from _cia_)).

#### Multipliers (Positive Powers)
| Factor | Prefix | Unicode Short | ASCII Short | Time Colloquial | Time Abbrev |
| :--- | :--- | :--- | :--- | :--- | :--- |
| $12^1$ | **unqua-** | `u↑` | `uq` | twinkling | `tw` |
| $12^2$ | **biqua-** | `b↑` | `bq` | lull | `lu` |
| $12^3$ | **triqua-** | `t↑` | `tq` | trice | `tr` |
| $12^4$ | **quadqua-**| `q↑` | `qq` | breather | `br` |
| $12^5$ | **pentqua-**| `p↑` | `pq` | dwell | `dw` |
| $12^6$ | **hexqua-** | `h↑` | `hq` | day | `dy` |

#### Subunits (Negative Powers)
| Factor | Prefix | Unicode Short | ASCII Short | Example (Unicode) | Example (ASCII) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| $12^{-1}$ | **uncia-** | `u↓` | `uc` | `u↓lgl` | `uclgl` |
| $12^{-2}$ | **bicia-** | `b↓` | `bc` | `b↓msl` | `bcmsl` |
| $12^{-3}$ | **tricia-** | `t↓` | `tc` | `t↓tml` | `tctml` |
| $12^{-4}$ | **quadcia-**| `q↓` | `qc` | `q↓lgl` | `qclgl` |
| $12^{-5}$ | **pentcia-**| `p↓` | `pc` | `p↓msl` | `pcmsl` |
| $12^{-6}$ | **hexcia-** | `h↓` | `hc` | `h↓tml` | `hctml` |

## 3. Primel Derived Units

These coherent derived units follow the exact same scaling as the base Primel units. All 12 Primel metric prefixes apply to these units (e.g., `unquavelocel`).

| Unit Name | Abbreviation | Definition | Physical Quantity |
| :--- | :--- | :--- | :--- |
| **Velocel** | `vlcl` | `lengthel / timel` | Velocity / Speed |
| **Accel** | `accl` | `lengthel / timel^2` | Acceleration |
| **Areal** | `arl` | `lengthel^2` | Area |
| **Volumel** | `vlml` | `lengthel^3` | Volume |
| **Forcel** | `frcl` | `massel * accel` | Force |
| **Pressel** | `prsl` | `forcel / areal` | Pressure |
| **Energel** | `engl` | `forcel * lengthel` | Energy / Work |
| **Powrel** | `pwrl` | `energel / timel` | Power |
| **Densel** | `dnsl` | `massel / volumel` | Density |

*Example usages: `qalc "1 pqfrcl"` (1 pentquaforcel) or `qalc "1 u↓vlcl"` (1 unciavelocel).*
