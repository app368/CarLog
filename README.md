# CarLog

A simple iPhone app for keeping track of one car's expenses: fuel, insurance and scheduled maintenance.

Made for a single owner with a handful of records — a fill-up once a month, insurance and service a couple of times a year.

## Features

- **Fuel** — date, odometer, gallons and total from the pump; price per gallon is calculated. Gas stations and fuel grades are kept in their own lists, and the last ones used are filled in automatically.
- **Insurance** — payments with company, amount and policy validity; expired policies are highlighted.
- **Maintenance** — three screens. Schedule: last and next date for each service with OK / Soon / Overdue status; mileage intervals are turned into dates using your average mileage. Visits: each trip to the service with date, service center, odometer and the lines of the service document — one line can cover several services at one price; pages of the document are scanned with the camera or added from Photos and open full screen with zoom. A visit can also be imported from a JSON file prepared from the document. Reference: services with intervals and notes, service groups (what is done together), the Acura dealer chart and service names with translations. The built-in list follows the 2014–2015 Acura MDX Maintenance Minder chart; every service can be edited.
- **Stats** — price per gallon and monthly spending charts; tap a chart to open it full screen in landscape.
- **Info** — car details; gas stations with notes and an address that opens in Apple Maps or Google Maps; service centers with address, website, phone and email that open maps, the browser, a call or a new message; export all records, including document pages, to a JSON file and import them back.

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
