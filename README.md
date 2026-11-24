# CarLog

A simple iPhone app for keeping track of one car's expenses and papers: fuel, insurance, registration and scheduled maintenance.

Made for a single owner with a handful of records — a fill-up once a month, insurance and service a couple of times a year.

## Features

- **Fuel** — date, odometer, gallons and total from the pump; price per gallon is calculated. Gas stations and fuel grades are kept in their own lists, and the last ones used are filled in automatically.
- **Documents** — insurance and registration, two lists under a switcher. Insurance: payments with company, policy number, amount and validity. Registration: renewals with the issuing office, fee and validity. Valid dates show in green, turning yellow 30 days before the end unless already renewed; an expired record shows in red until a newer one is added, then in blue; amounts are optional. Each record keeps its documents — scanned with the camera, picked from Photos or added as a file (a PDF stays a PDF) — and notes; documents open full screen with zoom and can be shared. Each insurance company keeps its contacts — claims line, customer service, phone, email, website and address — and shows the policy number from its latest payment.
- **Maintenance** — three screens. Schedule: last and next date for each service with OK / Soon / Overdue status; mileage intervals are turned into dates using your average mileage. Visits: each trip to the service with date, service center, odometer and the lines of the service document — one line can cover several services at one price; documents from the service are scanned with the camera, picked from Photos or added as a file and open full screen with zoom. Process Document shares them for processing and imports the visit file prepared from them; a visit can also be imported from such a file on its own. Reference: services with intervals and notes, service groups (what is done together), the Acura dealer chart and service names with translations. The built-in list follows the 2014–2015 Acura MDX Maintenance Minder chart; every service can be edited.
- **Stats** — price per gallon and monthly spending charts; tap a chart to open it full screen in landscape.
- **Info** — car details; emergency contacts: 911, police non-emergency lines, the DMV crash report line and the insurance claims line, each one tap to call; an accident guide for Oregon in English and Russian, as a checklist with call buttons; gas stations with notes and an address that opens in Apple Maps or Google Maps; service centers and insurance companies with address, website, phone and email that open maps, the browser, a call or a new message; export all records, including document pages, to a JSON file and import them back.

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
