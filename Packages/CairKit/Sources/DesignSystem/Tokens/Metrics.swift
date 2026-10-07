import CoreGraphics

/// Spacing scale (4 pt base).
public enum CairSpace {
    public static let xxs: CGFloat = 4
    public static let xs: CGFloat = 8
    public static let s: CGFloat = 12
    public static let m: CGFloat = 16
    public static let l: CGFloat = 24
    public static let xl: CGFloat = 32
    public static let xxl: CGFloat = 48
    public static let xxxl: CGFloat = 64
    public static let hero: CGFloat = 96
}

public enum CairRadius {
    public static let chip: CGFloat = 10
    public static let control: CGFloat = 18
    public static let card: CGFloat = 28
    public static let panel: CGFloat = 36
}

public enum CairStroke {
    public static let hairline: CGFloat = 0.5
    public static let rule: CGFloat = 1
    public static let emphasis: CGFloat = 1.5
}

public enum CairSize {
    /// Minimum hit target (Apple HIG).
    public static let minTouch: CGFloat = 44
    /// Width of the Chronicles / Media Hub folio panel on iPad.
    public static let panelWidth: CGFloat = 400
}
