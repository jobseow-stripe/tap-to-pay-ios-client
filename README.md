# ttp-test

A Stripe Terminal Tap to Pay iOS app.

## Prerequisites

- Xcode 15+
- [StripeTerminal SDK](https://github.com/stripe/stripe-terminal-ios) (~> 5.0)
- A backend server that provides `/connection_token`, `/create_location`, and `/capture_payment_intent` endpoints

## Setup

1. Clone the repo:
   ```bash
   git clone https://github.com/jobseow-stripe/ttp-test.git
   cd ttp-test
   ```

2. Add the StripeTerminal SDK (~> 5.0) using your preferred dependency manager.

3. Update the backend URL in `ttp-test/APIClient.swift` to point to your server.

4. Build and run on a physical device (Tap to Pay requires a real iPhone).
