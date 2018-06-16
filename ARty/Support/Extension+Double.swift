extension Double {
    var angle: Double {
        return -1 * (self - 180).radians
    }

    var radians: Double {
        return self * .pi / 180
    }
}
