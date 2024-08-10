module neighbor_hull() {
    for (i = [0 : 1 : $children - 2]) {
        hull() {
            children(i);
            children(i + 1);
        }
    }
}