---
description: Perform a thorough code review as a senior software engineer
globs: **/*.py
alwaysApply: false
---

# Code Review Guidelines

Perform a thorough code review that emphasizes maintainability with a constructive and educational mindset. Provide specific, actionable feedback with concrete code suggestions. Focus on important issues and balance thoroughness with pragmatism.

## Output Format

Create a code review document named `<feature>-cr.md` in the project root (or appropriate docs directory). The document should:
1. Start with a summary section listing files reviewed
2. Organize findings by severity: Critical, Important, Minor
3. Include concrete code examples for each issue
4. End with a checklist of items to address

If the feature name is not clear from context, ask the user for a short feature name (e.g., "offset-calculation", "websocket-auth", "spike-detection").

## Key Focus Areas

### 1. Logic Simplification

Look for opportunities to simplify complex logic using guard clauses and early returns:

✅ **Good:**
```python
def is_eligible(user: User) -> bool:
    # Guard clauses to return early
    if not user.is_active:
        return False
    if user.age < 18:
        return False

    # Simple, direct logic
    return user.subscription_type == 'premium'
```

❌ **Bad:**
```python
def is_eligible(user: User) -> bool:
    is_eligible = False

    if user.is_active:
        if user.age >= 18:
            if user.subscription_type == 'premium':
                is_eligible = True

    return is_eligible
```

### 2. DRY (Don't Repeat Yourself)

Identify and eliminate code duplication:

✅ **Good:**
```python
def validate_input(input_str: str, field_name: str) -> ValidationResult:
    trimmed = input_str.strip()

    if not trimmed:
        return ValidationResult(valid=False, error=f'{field_name} cannot be empty')

    if len(trimmed) < 3:
        return ValidationResult(valid=False, error=f'{field_name} must be at least 3 characters')

    return ValidationResult(valid=True)

# Usage
validate_input(name, 'Name')
validate_input(title, 'Title')
```

❌ **Bad:**
```python
def validate_name(name: str) -> ValidationResult:
    trimmed = name.strip()

    if not trimmed:
        return ValidationResult(valid=False, error='Name cannot be empty')

    if len(trimmed) < 3:
        return ValidationResult(valid=False, error='Name must be at least 3 characters')

    return ValidationResult(valid=True)

def validate_title(title: str) -> ValidationResult:
    trimmed = title.strip()

    if not trimmed:
        return ValidationResult(valid=False, error='Title cannot be empty')

    if len(trimmed) < 3:
        return ValidationResult(valid=False, error='Title must be at least 3 characters')

    return ValidationResult(valid=True)
```

### 3. Comment Quality

Ensure comments are relevant, accurate, and add value. Remove obvious or redundant comments:

✅ **Good:**
```python
def calculate_discounted_price(unit_price: float, quantity: int) -> float:
    # Volume discounts apply for quantities over 10 units
    discount_rate = determine_discount_rate(quantity)
    return unit_price * quantity * (1 - discount_rate)
```

❌ **Bad:**
```python
# Get the price
# TODO: Add discount later
# This function returns the final price
def calculate_discounted_price(unit_price: float, quantity: int) -> float:
    # Multiply unit price by quantity
    total = unit_price * quantity

    # Determine discount rate
    discount_rate = determine_discount_rate(quantity)

    # Apply discount
    return total * (1 - discount_rate)
```

### 4. Return Early Pattern

Enforce the return early pattern to reduce nesting and improve readability:

✅ **Good:**
```python
def process_order(order: Order) -> ProcessResult:
    if not order.items:
        return ProcessResult(success=False, error='Order has no items')

    if not order.shipping_address:
        return ProcessResult(success=False, error='Shipping address is required')

    if not is_valid_payment_method(order.payment_method):
        return ProcessResult(success=False, error='Invalid payment method')

    # Process the valid order
    result = submit_order_to_system(order)
    return ProcessResult(success=True, order_id=result.id)
```

❌ **Bad:**
```python
def process_order(order: Order) -> ProcessResult:
    if order.items:
        if order.shipping_address:
            if is_valid_payment_method(order.payment_method):
                # Process the valid order
                result = submit_order_to_system(order)
                return ProcessResult(success=True, order_id=result.id)
            else:
                return ProcessResult(success=False, error='Invalid payment method')
        else:
            return ProcessResult(success=False, error='Shipping address is required')
    else:
        return ProcessResult(success=False, error='Order has no items')
```

### 5. Restoring Missing Logic

Check for and restore logic marked with "TODO: restore" comments:

✅ **Good (Restored):**
```python
def calculate_total(items: list[Item]) -> float:
    total = 0.0

    for item in items:
        # Apply discount for eligible items
        if item.is_discount_eligible:
            total += item.price * (1 - item.discount_rate)
        else:
            total += item.price

    # Apply tax
    total *= 1.08

    return total
```

❌ **Bad (Unrestored):**
```python
def calculate_total(items: list[Item]) -> float:
    total = 0.0

    for item in items:
        # TODO: restore
        # if item.is_discount_eligible:
        #     total += item.price * (1 - item.discount_rate)
        # else:
        #     total += item.price
        total += item.price

    # TODO: restore
    # Apply tax
    # total *= 1.08

    return total
```

### 6. Boolean Variable Naming

Ensure boolean variables and functions use the "is_", "should_", "can_", "has_" prefix:

✅ **Good:**
```python
is_active = user.status == 'active'
should_show_warning = attempts > 3
can_edit = user.has_permission('edit')
has_errors = len(errors) > 0

def is_valid_email(email: str) -> bool:
    return EMAIL_REGEX.match(email) is not None
```

❌ **Bad:**
```python
active = user.status == 'active'
show_warning = attempts > 3
edit_permission = user.has_permission('edit')
errors_exist = len(errors) > 0

def validate_email(email: str) -> bool:
    return EMAIL_REGEX.match(email) is not None
```

### 7. No Default Config Values

Config parsing must fail fast on missing fields:

✅ **Good:**
```python
@dataclass
class DetectorConfig:
    threshold_bps: float  # No default - must be in config
    timeout_sec: int

def _load_config(self) -> DetectorConfig:
    return DetectorConfig(
        threshold_bps=self._require_float("DETECTOR", "THRESHOLD_BPS"),
        timeout_sec=self._require_int("DETECTOR", "TIMEOUT_SEC"),
    )
```

❌ **Bad:**
```python
@dataclass
class DetectorConfig:
    threshold_bps: float = 15.0  # Hidden default
    timeout_sec: int = 30

def _load_config(self) -> DetectorConfig:
    return DetectorConfig(
        threshold_bps=section.getfloat("THRESHOLD_BPS", fallback=15.0),
        timeout_sec=section.getint("TIMEOUT_SEC", fallback=30),
    )
```

### 8. Pythonic Code

Use Python idioms and best practices:

✅ **Good:**
```python
# Use list comprehensions
active_users = [user for user in users if user.is_active]

# Use dict comprehensions
user_map = {user.id: user for user in users}

# Use enumerate instead of range(len())
for i, item in enumerate(items):
    print(f"Item {i}: {item}")

# Use context managers
with open('file.txt', 'r') as f:
    content = f.read()
```

❌ **Bad:**
```python
# Manual list building
active_users = []
for user in users:
    if user.is_active:
        active_users.append(user)

# Manual dict building
user_map = {}
for user in users:
    user_map[user.id] = user

# Using range(len())
for i in range(len(items)):
    print(f"Item {i}: {items[i]}")

# Manual file handling
f = open('file.txt', 'r')
content = f.read()
f.close()
```

## Final Checklist

Before completing the review:

1. ✅ Verify all required functionality is implemented
2. ✅ Check for edge cases and potential errors
3. ✅ Look for security vulnerabilities
4. ✅ Ensure code follows PEP 8 and project style guidelines
5. ✅ Ask if tests should be included:
   - Unit tests for individual functions
   - Integration tests for component interactions
   - End-to-end tests for critical flows
6. ✅ **Check for and remove any remaining `print()` statements used for debugging**
7. ✅ **Ensure all unused imports are removed**
8. ✅ **Verify that there are no unused variables**
9. ✅ **Address linter warnings/errors purely stylistically, without altering the underlying logic**
10. ✅ **Confirm you've provided concrete code suggestions for all issues identified**

Remember: Code review is about improving code quality while fostering a collaborative, positive team culture. Provide constructive feedback with specific code improvements and be open to discussion.

## Final Step

After completing the review, write all findings to `<feature>-cr.md` using the Write tool. Structure the document with:
- Summary section (files reviewed, overall assessment)
- Critical Issues (must fix before merge)
- Important Issues (should fix before merge)
- Minor Issues (nice to have)
- Action Items Checklist

Inform the user that the code review has been written to the file.
