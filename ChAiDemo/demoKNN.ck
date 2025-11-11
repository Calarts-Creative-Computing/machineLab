KNN knn;
[[0.0, 0.0], [1.0, 1.0], [2.0, 2.0]] @=> float features[][];
knn.train(features);
[0.5, 0.5] @=> float query[];
int indices[0];
knn.search(query, 2, indices);
chout <= "indices size:" <= indices.size() <= IO.newline();