# CarLog

A simple iPhone app for keeping track of one car's expenses: fuel, insurance and scheduled maintenance.

Made for a single owner with a handful of records — a fill-up once a month, insurance and service a couple of times a year.

## Features

- **Fuel** — date, odometer, gallons and total from the pump; price per gallon is calculated. Gas stations and fuel grades are kept in their own lists, and the last ones used are filled in automatically.
- **Insurance** — payments with company, amount and policy validity; expired policies are highlighted.
- **Service** — history of maintenance work plus a maintenance schedule with OK / Soon / Overdue status based on mileage and time. The built-in preset follows the 2014–2015 Acura MDX Maintenance Minder chart; every interval can be edited.
- **Stats** — price per gallon and monthly spending charts; tap a chart to open it full screen in landscape.
- **Car** — manufacturer, make, model, year, VIN and plate; export all records to a JSON file and import them back.

Units are US: gallons, miles and dollars. All data stays on the device (SwiftData).

## Requirements

- Xcode 26 or later
- iOS 17 or later

## Building

1. Clone the repository and open `CarLog.xcodeproj`.
2. Create `Local.xcconfig` next to the project with your own signing values:

   ```
   DEVELOPMENT_TEAM = YOUR_TEAM_ID
   PRODUCT_BUNDLE_IDENTIFIER = com.yourname.CarLog
   ```

   `Signing.xcconfig` includes it automatically; `Local.xcconfig` is ignored by git.
3. Select your iPhone or a simulator and run.

The project builds for the simulator without `Local.xcconfig`.

## License

[MIT](LICENSE)
