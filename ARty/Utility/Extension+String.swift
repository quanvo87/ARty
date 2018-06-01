extension String {
    var isWalkAnimation: Bool {
        return schema.walkAnimations.contains(self)
    }

    var isFallAnimation: Bool {
        return schema.fallAnimations.contains(self)
    }

    var animationDisplayName: String {
        if let index = self.range(of: "_")?.upperBound {
            return String(self.suffix(from: index)).capitalized
        } else {
            return self
        }
    }
}
