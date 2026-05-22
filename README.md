# QuickService

A tiny, dependency-light Ruby gem for the **Service Object** pattern.

`QuickService` gives you one base class — `QuickService::Service` — that
standardizes how services are called and how they report success or failure
back to the caller.

## Installation

Add it to your `Gemfile`:

```ruby
gem 'quick_service'
```

Then run `bundle install`. Its only runtime dependency is `activesupport`.

## Usage

Inherit from `QuickService::Service`, define `initialize` for your inputs and
`call` for the work:

```ruby
class Invoices::ApproveService < QuickService::Service
  def initialize(invoice:, user:)
    @invoice = invoice
    @user = user
  end

  def call
    fail!(base: 'Not authorized') unless authorized?

    @invoice.update!(status: :approved)
    success(invoice: @invoice)
  end

  private

  def authorized?
    @user.admin?
  end
end

result = Invoices::ApproveService.call(invoice: invoice, user: user)

if result.success?
  result.invoice # => the approved invoice
else
  result.base    # => 'Not authorized'
end
```

A service that never calls `success`/`fail`/`fail!` is considered **successful
by default**.

### Result object

Every `.call` returns a `QuickService::Service::ServiceResult`:

| Method        | Description                                          |
| ------------- | ---------------------------------------------------- |
| `success?` / `succeeded?` | `true` when the service succeeded        |
| `fail?` / `failed?`       | `true` when the service failed           |
| `data`        | hash of values passed to `success` (indifferent access) |
| `errors`      | hash of values passed to `fail`/`fail!` (indifferent access) |

Read a value with `result[:key]` — the canonical, collision-free accessor;
it raises `KeyError` if the key is absent. `result.key` is shorthand for the
same lookup (`data` on success, `errors` on failure) and raises
`NoMethodError` for an unknown key. Keys whose names collide with real
methods (`data`, `errors`, `class`, …) are reachable only via `[]`. For
optional values, use `result.respond_to?(:key)` or `result.try(:key)`.

### Reporting outcomes

| Method            | Effect                                                   |
| ----------------- | -------------------------------------------------------- |
| `success(data)`   | mark as successful, **keep running**                     |
| `fail(errors)`    | mark as failed, **keep running**                         |
| `success!(data)`  | mark as successful and **stop execution immediately**    |
| `fail!(errors)`   | mark as failed and **stop execution immediately**        |

The last of `success`/`fail` to run wins. `success!` and `fail!` halt via
`throw`/`catch`, so the unwind cannot be swallowed by a `rescue` inside your
own `call`.

### Nested services: `call` vs `call!`

```ruby
class ParentService < QuickService::Service
  def call
    # `.call` swallows the inner failure — this service still succeeds
    ChildService.call(...)

    # `.call!` re-raises the inner failure — this service fails too
    ChildService.call!(...)

    success(done: true)
  end
end
```

- `.call` — never raises on a nested failure; check `result.fail?` yourself.
- `.call!` — re-raises a `ServiceError` when the result failed, so the
  failure cascades up to the nearest plain `.call`.

### Validating with form objects

If you pass objects that respond to `#valid?` and `#errors.messages` (e.g.
ActiveModel forms), there are helpers to fold validation into a service:

```ruby
def call
  validate_with(:user, user_form)        # fail softly, keep running
  validate_with!(:user, user_form)       # fail and halt
  validate_pipeline(                     # validate many, collect all errors
    user: user_form,
    address: address_form
  )
  success(user: user_form.save)
end
```

## Configuration

```ruby
QuickService.configure do |config|
  config.enforce_interface = true
end
```

With `enforce_interface = true`, every service **must** define its own
`initialize` — subclasses that rely on the default raise `NotImplementedError`.
This nudges you toward explicit, keyword-argument interfaces.

## Development

```bash
bin/setup        # install dependencies
bundle exec rake # run the test suite
bin/console      # an IRB session with the gem loaded
```

## License

Released under the [MIT License](LICENSE.txt).
