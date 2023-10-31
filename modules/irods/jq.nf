process JSON_PREP {
    label 'cpu_2_mem_1_time_1'

    input:
    val(input_name)

    output:
    path(json_file), emit: path_channel

    script:
    json_file="input.json"
    if (input_name.isNumber())
        """
        jq -n '{op: "metaquery", args: {object: true}, target: {avus: [{a: "study_id", v: "${input_name}"}, {a: "target", v: "1"}, {a: "type", v: "cram"}]}}' > ${json_file}
        """
    else if (!input_name.isNumber())
        """
        jq -n '{op: "metaquery", args: {object: true}, target: {avus: [{a: "study", v: "${input_name}"}, {a: "target", v: "1"}, {a: "type", v: "cram"}]}}' > ${json_file}
        """
    else
        error "unrecognised study input"
}

process JSON_PARSE {
    label 'cpu_2_mem_1_time_1'
    input:
    path(lane_file)

    output:
    stdout

    script:
    lanes = "lanes_file.txt"
    """
    jq '.result[] | .collection + "/" + .data_object' ${lane_file}
    """
}