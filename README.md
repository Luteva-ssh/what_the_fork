# What The Fork 🍴

A terminal tool that analyzes forks of a GitHub repository to extract and categorize changes like bugfixes, new features, and improvements. Discover what the community has been working on in repository forks!
(Note: This project is vibe-coded!)

## Features

- **Comprehensive Fork Analysis**: Analyzes all forks of a given GitHub repository
- **Smart Categorization**: Automatically categorizes commits into:
  - 🚀 **Features**: New functionality and enhancements
  - 🐛 **Bugfixes**: Bug fixes and problem resolutions
  - 💡 **Ideas**: Improvements, refactoring, and optimizations
- **Activity-Based Sorting**: Prioritizes forks by star count and recent activity
- **Rate Limit Friendly**: Respects GitHub API limits with automatic delays
- **Token Support**: Optional GitHub token support for higher API rate limits

## Installation

### Prerequisites
- Nim compiler (>= 2.2.4)

### Build from Source
```bash
git clone https://github.com/your-username/what_the_fork
cd what_the_fork
nimble build
```

The compiled binary will be available in the `bin/` directory.

## Usage

```bash
what_the_fork <github_url> [github_token]
```

### Arguments

- **github_url**: GitHub repository URL in one of these formats:
  - `https://github.com/owner/repo`
  - `https://github.com/owner/repo.git`
  - `github.com/owner/repo`
  - `owner/repo`

- **github_token** (optional): GitHub personal access token for higher API rate limits
  - Without token: 60 requests/hour
  - With token: 5000 requests/hour
  - Get your token at: https://github.com/settings/tokens

### Examples

```bash
# Basic usage
what_the_fork https://github.com/nim-lang/Nim

# Short format
what_the_fork nim-lang/Nim

# With GitHub token for higher rate limits
what_the_fork https://github.com/nim-lang/Nim ghp_your_token_here

# Analyze Ormin ORM forks
what_the_fork https://github.com/Araq/ormin
```

## Example Output

Here's what you'll see when analyzing the Ormin repository:

```
🔍 Analyzing forks of Araq/ormin...
📥 Fetching forks...
✅ Found 20 forks
🔬 Analyzing top 10 most active forks...

⏳ Analyzing sair770/ormin (1/10)...
================================================================================
🍴 FORK: sair770/ormin
================================================================================
⭐ Stars: 1 | 🍴 Forks: 0
📝 Description: Ormin -- An ORM for Nim. 
🔗 URL: https://github.com/sair770/ormin
📅 Last Updated: 2023-03-08T01:43:58Z
📊 Total Commits Analyzed: 73

🚀 FEATURES (10):
----------------------------------------
  • [PMunch] Implement named tuples (#12)
  • [Andreas Rumpf] first implementation of serverhttp
  • [Andreas Rumpf] fixes the protocol implementation; export all generated fields
  • [Andreas Rumpf] added support for globals in the client section
  • [Andreas Rumpf] protocol macro: added support for 'common' sections
  • [Andreas Rumpf] added support for the 'bool' type
  • [Andreas Rumpf] added support for 'case when'
  • [Andreas Rumpf] better support for verbatim SQL
  • [Andreas Rumpf] added ormin_sqlite implementation
  • [Andreas Rumpf] implemented backend specific placeholder

🐛 BUGFIXES (1):
----------------------------------------
  • [Andreas Rumpf] ormin_importer: proper error handling

⏳ Analyzing PMunch/ormin (2/10)...
.......
...

================================================================================
📊 SUMMARY
================================================================================
🍴 Total Forks: 20
🔬 Analyzed: 10
🚀 Total Features Found: 45
🐛 Total Bugfixes Found: 12
💡 Total Ideas/Improvements Found: 23
📈 Total Insights: 80
```

## How It Works

1. **Fetches Forks**: Retrieves all forks of the specified repository using GitHub API
2. **Sorts by Activity**: Ranks forks by star count to focus on the most active ones
3. **Analyzes Commits**: Examines recent commits from each fork's default branch
4. **Categorizes Changes**: Uses pattern matching on commit messages to categorize:
   - Features: `feat:`, `add:`, `implement`, `new:`, etc.
   - Bugfixes: `fix:`, `bug:`, `resolve`, `issue`, etc.
   - Ideas: `improve:`, `refactor:`, `optimize:`, `enhance`, etc.
5. **Generates Report**: Provides a comprehensive summary of findings

## Limitations

- Analyzes up to 10 most active forks by default
- Examines up to 90 recent commits per fork
- Categorization depends on commit message patterns
- Subject to GitHub API rate limits

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## License

MIT License - see LICENSE file for details.

