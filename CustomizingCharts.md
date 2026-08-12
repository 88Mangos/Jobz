# Customizing Chart Colors in Jobz

The Jobz dashboard utilizes Swift Charts to render beautiful and responsive analytics. By default, Swift Charts picks a nice palette of colors, but you can easily customize them to fit your own personal aesthetic.

## How to Customize Colors

To override the default colors for any chart, you need to use the `.chartForegroundStyleScale` modifier.

### 1. Status Breakdown Chart

Open `Jobz/Views/Dashboard/StatusBreakdownChart.swift` and locate the `Chart` block.

Add the `.chartForegroundStyleScale` modifier directly to the `Chart`, mapping each `ApplicationStatus` to a specific SwiftUI `Color`:

```swift
Chart(statusCounts, id: \.status) { item in
    BarMark(
        x: .value("Status", item.status.rawValue),
        y: .value("Count", item.count)
    )
    .foregroundStyle(by: .value("Status", item.status.rawValue))
}
.chartForegroundStyleScale([
    "Accepted": Color.green,
    "Offered": Color.mint,
    "Interviewing": Color.blue,
    "Pending": Color.gray,
    "Ghosted": Color.orange,
    "Rejected": Color.red
])
```

### 2. Applications Over Time (Line/Area Chart)

Open `Jobz/Views/Dashboard/ApplicationsOverTimeChart.swift`. Because this chart only has a single data series (total applications), you can customize the color by directly modifying the `.foregroundStyle` of the `LineMark` and `AreaMark`:

```swift
LineMark(
    x: .value("Date", item.date, unit: .day),
    y: .value("Applications", item.count)
)
.foregroundStyle(Color.indigo) // Change this line color
.interpolationMethod(.monotone)

AreaMark(
    x: .value("Date", item.date, unit: .day),
    y: .value("Applications", item.count)
)
.foregroundStyle(Color.indigo.opacity(0.15)) // Change this area color
```

### 3. Weekly Goal Donut Chart

Open `Jobz/Views/Dashboard/WeeklyGoalDonutChart.swift`.

In this chart, we explicitly set the color inside the `SectorMark`'s foreground style. You can change these colors to match your theme:

```swift
SectorMark(
    angle: .value("Count", item.count),
    innerRadius: .ratio(0.65),
    angularInset: 1.5
)
// Update the colors below
.foregroundStyle(item.category == "Applied" ? Color.indigo : Color.secondary.opacity(0.2))
```

## Best Practices
- **Dark Mode Support**: Use semantic colors like `Color.blue` or `Color.accentColor` rather than strict hex codes, as semantic colors automatically adjust their vibrance for Dark Mode.
- **Custom Assets**: If you want to use custom brand colors, define a Color Set in `Assets.xcassets` and use `Color("MyCustomColor")`.
