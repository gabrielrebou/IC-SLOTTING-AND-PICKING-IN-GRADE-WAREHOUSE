# usando o k-means++ "K-means++: The Advantages of Careful Seeding." SODA 2007.
# futuramente utilizar o elbow method ou silhouette score para determinar o número ideal de clusters
# futuramente usar normalização dos dados para melhorar a performance do k-means
# futuramente usar svd para reduzir a dimensionalidade dos dados antes de aplicar o k-means

using Clustering
using Random

function kmeans_clusters(cooc, k::Int)
    Random.seed!(1234)

    X = Float64.(permutedims(cooc.matrix))

    result = kmeans(
        X,
        k;
        init = :kmpp, #k-means++
        maxiter = 200
    )

    clusters = Cluster[]

    for c in 1:k

        skus = Int[]
        total_frequency = 0

        for (sku, cluster) in enumerate(result.assignments)

            if cluster == c
                push!(skus, sku)
                total_frequency += cooc.frequency[sku]
            end

        end

        average_frequency =
            isempty(skus) ? 0.0 : total_frequency / length(skus)

        push!(clusters, Cluster(skus, average_frequency))

    end

    return ClusteringResult(clusters)

end


function internal_cooccurrence(cluster, cooc)

    total = 0

    for i in 1:length(cluster.skus)-1
        for j in i+1:length(cluster.skus)

            s1 = cluster.skus[i]
            s2 = cluster.skus[j]

            total += cooc.matrix[s1, s2]
        end
    end

    return total
end