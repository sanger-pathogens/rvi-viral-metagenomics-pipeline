//generates a list starting from a sample seed given by parameter until the number of iterations is met
//This is then used to trigger the subsampling process as many times as there are in the list generating
//multiple iterations of subsampling
def seed_list() {
    return (params.subsample_seed .. params.subsample_iterations + params.subsample_seed - 1).toList()
}
