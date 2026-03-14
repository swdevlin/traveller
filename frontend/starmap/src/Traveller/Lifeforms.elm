module Traveller.Lifeforms exposing (bioChemistryCompatibilityDescription, biocomplexityDescription, biodiversityDescription, biomassDescription, habitabilityDescription)


biomassDescription : Int -> String
biomassDescription rating =
    case rating of
        0 ->
            "None (No native life exists; surface and atmosphere sterile)"

        1 ->
            "Trace (Microscopic or sparse microbial life, often in isolated niches)"

        2 ->
            "Very Low (Thin biosphere, with small colonies of hardy species; biomass barely detectable from orbit)"

        3 ->
            "Low (Life present in limited habitats, such as only in oceans, lakes, or certain regions)"

        4 ->
            "Moderate-Low (Ecosystems present but not lush; limited vegetation and animal density)"

        5 ->
            "Moderate (Noticeable biomass in most regions; productive ecosystems but still thin compared to fertile worlds)"

        6 ->
            "Moderate-High (Healthy and varied biomass in most regions; large, stable food webs)"

        7 ->
            "High (Dense plant and animal life in most biomes; little uncolonised surface)"

        8 ->
            "Very High (Rich biomass with extreme density in some regions; ecosystems highly productive year-round)"

        9 ->
            "Abundant (Biomass so high it shapes climate and geology; ecosystems are resilient and self-repairing)"

        10 ->
            "Garden World (Equivalent to pre-human Terra; lush, balanced, and productive biosphere across the planet)"

        _ ->
            if rating < 0 then
                "None (No native life exists; surface and atmosphere sterile)"

            else
                "Hyper-abundant (More biomass than pre-human Terra; alien biochemistries or evolutionary histories have produced extreme productivity)"


biodiversityDescription : Int -> String
biodiversityDescription code =
    case code of
        0 ->
            "Sterile – No detectable biomass. Lifeless rock, ice, or gas; may have organics but no living organisms."

        1 ->
            "Trace Life – Microbes or simple extremophiles in niche environments; no visible macroscopic life."

        2 ->
            "Minimal – Simple ecosystems with only a few hardy species; mostly barren terrain with scattered life pockets."

        3 ->
            "Sparse – Low diversity; a small number of dominant species across most environments."

        4 ->
            "Limited – Multiple species present, but ecosystems remain simple and repetitive."

        5 ->
            "Moderate – Distinct ecosystems present, but limited species turnover; a ‘familiar’ set of organisms across large areas."

        6 ->
            "Developing – Several well-defined ecosystems with moderate inter-species complexity; seasonal or regional variety."

        7 ->
            "Rich – Diverse biomes with strong species variety; food webs are complex but not maximal."

        8 ->
            "Very Rich – Highly varied ecosystems with strong regional specialisation; many niches filled."

        9 ->
            "Abundant – Dense, highly interconnected food webs; ecosystems recover quickly from disruption."

        10 ->
            "Terra-Equivalent – Biodiversity equal to pre-human Earth; extremely complex, stable, and resilient biosphere."

        _ ->
            "Hyperdiverse – More complex than pre-human Earth; alien biochemistries or evolutionary histories have produced extreme species variety."


biocomplexityDescription : Int -> String
biocomplexityDescription rating =
    case rating of
        1 ->
            "Primitive single-cell organisms – Procaryotes such as bacteria and archaea."

        2 ->
            "Advanced cellular organisms – Eucaryotes such as algae and amoebae."

        3 ->
            "Primitive multicellular organisms – Lichen, sponges, some fungi."

        4 ->
            "Differentiated multicellular organisms – Ediacaran and early Cambrian age creatures."

        5 ->
            "Complex multicellular organisms – Insects, ferns, fish."

        6 ->
            "Advanced multicellular organisms – Reptiles, birds, mammals, flowering plants."

        7 ->
            "Socially advanced organisms – Ants, bees, primates, elephants."

        8 ->
            "Mentally advanced organisms – Sophont intelligence, psionics."

        9 ->
            "Extant or extinct sophonts – At some point, this world had sophont lifeforms."

        10 ->
            "Ecosystem-wide superorganisms – Cooperative sophont-like behaviour."

        _ ->
            "Unknown biocomplexity rating."


bioChemistryCompatibilityDescription : Int -> String
bioChemistryCompatibilityDescription compatibilityRating =
    if compatibilityRating < 10 then
        String.fromInt (compatibilityRating * 10) ++ "%"

    else
        "100% compatible"


habitabilityDescription : Maybe Int -> String
habitabilityDescription maybeRating =
    let
        ratingToString rating =
            case rating of
                0 ->
                    "Actively hostile world: not survivable without specialised equipment"

                1 ->
                    "Barely habitable world: full protective equipment often needed"

                2 ->
                    "Barely habitable world: full protective equipment often needed"

                3 ->
                    "Marginally survivable world with proper equipment"

                4 ->
                    "Marginally survivable world with proper equipment"

                5 ->
                    "Marginally survivable world with proper equipment"

                6 ->
                    "Regionally habitable world: may require acclimation"

                7 ->
                    "Regionally habitable world: may require acclimation"

                8 ->
                    "Suitable for human habitation with minimal equipment or acclimation"

                9 ->
                    "Suitable for human habitation with minimal equipment or acclimation"

                _ ->
                    "Terra-equivalent garden world"
    in
    maybeRating
        |> Maybe.map ratingToString
        |> Maybe.withDefault "N/A"
