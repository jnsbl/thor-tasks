# Thor Tasks

    Modules      Namespaces
    -------      ----------
    gen.thor     gen
    dockit.thor  dockit:cmd

    dockit
    ------
    thor dockit:cmd:alt_scenarios INPUT_DIR  # Convert indent-based text file into JSON file with uuCommand alternative scenarios
    thor dockit:cmd:desc_list INPUT_DIR      # Generate JSON files with uuCommand description for uuDocKit
    thor dockit:cmd:error_list INPUT_DIR     # Extract list of errors from uuCommand alternative scenarios
    thor dockit:cmd:flow INPUT_DIR           # Convert indent-based text file into JSON file with uuCommand flow

    gen
    ---
    thor gen:id    # Generate random 32-char hexadecimal identifier
    thor gen:uuid  # Generate Universally Unique Identifier v4 (random)
