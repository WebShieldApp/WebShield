# Issue Reporting Guidelines

Thank you for using WebShield! Before submitting an issue, please take a moment to read through these guidelines to ensure that your report is actionable and helps us improve the project efficiently.

## Types of Issues to Report

### **Bug Reports**
We handle issues related to WebShield itself (e.g., performance, incorrect rule application, crashes) but **do not maintain filter lists**. If you are experiencing problems with specific websites (ads not being blocked or incorrect blocking), the issue might lie with the **filter list**, and you should report it to the respective filter list maintainer (e.g., [EasyList](https://easylist.to)). Ensure that the only extension being used is WebShield, and you are using Safari **not** Safari TP.

Examples of WebShield-related bugs:
- WebShield crashes or causes Safari to slow down.
- Filter rules are not being applied properly (e.g., syntax errors or rule implementation issues).
- UI or configuration issues (e.g., adding/removing filter lists not working as expected).

### **Feature Requests**
If you have an idea for improving WebShield, we’d love to hear about it! Please ensure that your request is aligned with the project's goals and current scope (Safari ad-blocking, privacy protection, and performance).

## Before Submitting an Issue

Please complete the following checklist before opening an issue:

- [ ] **Check for duplicates**: Search the [issue tracker](https://github.com/user/webshield/issues) to see if the issue has already been reported or addressed.
- [ ] **Update to the latest version**: Ensure you are using the latest version of WebShield. Issues reported for outdated versions may be closed.
- [ ] **Verify the issue is related to WebShield**: If the issue is specific to a filter list (e.g., ads not being blocked), it should be reported to the list maintainer, not WebShield.

## Bug Report Template

Please follow this template to ensure we can understand and replicate the issue:

### Bug Summary

A clear and concise description of what the bug is.

**Steps to Reproduce**:
(Example)
1. Go to '...'
2. Click on '...'
3. Scroll down to '...'
4. See error

**Expected Behavior**:
What you expected to happen.

**Actual Behavior**:
What actually happened.

**Environment**:
- macOS/iOS/iPadOS/visionOS version:
- Safari version:
- WebShield version:
- Filter lists being used (include links or names):
- Any other extensions being used alongside WebShield:

**Additional Context (Logs, Screenshots, etc.)**:
Please include any relevant logs, screenshots, or screen recordings that may help us debug the issue. Logs can be accessed by following these steps:
1. Open WebShield.
2. Navigate to **Preferences** > **Debug**.
3. Copy the log output and paste it here.

## Feature Request Template

We are always open to considering new features that improve WebShield. Please follow this template to submit a feature request:

### Feature Summary

A concise description of the feature you are proposing.

**Use Case**:
Explain why this feature is needed and how it would improve WebShield. Provide examples if possible.

**Proposed Solution**:
How should this feature work? Be as detailed as possible.

**Alternatives Considered**:
List any alternative solutions you have considered, if applicable.

## Where to Report Filter List Issues

Since WebShield does not host or maintain filter lists, please report filter list-related issues directly to the maintainers of those lists.

If the issue is due to an ad-blocking rule not being applied correctly due to a bug in WebShield, feel free to open an issue here and include relevant details.

## Additional Resources

- **WebShield Documentation**: [Link to documentation](https://github.com/webshieldapp/webshield/wiki)
- **GitHub Discussions**: [Join the conversation](https://github.com/webshieldapp/webshield/discussions)
