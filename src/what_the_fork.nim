import std/[httpclient, json, strutils, strformat, os, re, algorithm]

type
  Fork = object
    name: string
    fullName: string
    owner: string
    description: string
    stars: int
    forks: int
    lastUpdated: string
    defaultBranch: string
    url: string
    cloneUrl: string
    
  Commit = object
    sha: string
    message: string
    author: string
    date: string
    
  Analysis = object
    features: seq[string]
    bugfixes: seq[string]
    ideas: seq[string]
    commits: seq[Commit]

proc parseGitHubUrl(url: string): tuple[owner: string, repo: string] =
  ## Parse GitHub URL to extract owner and repository name
  let cleanUrl = url.strip()
  
  # Try different patterns for GitHub URLs
  let patterns = [
    re"https?://github\.com/([^/]+)/([^/]+?)(?:\.git)?/?$",  # https://github.com/owner/repo
    re"github\.com/([^/]+)/([^/]+?)(?:\.git)?/?$",           # github.com/owner/repo
    re"^([^/]+)/([^/]+?)(?:\.git)?$"                         # owner/repo
  ]
  
  var matches: array[2, string]
  
  for pattern in patterns:
    if cleanUrl.match(pattern, matches):
      var repo = matches[1]
      # Remove .git suffix if present
      if repo.endsWith(".git"):
        repo = repo[0..^5]
      return (owner: matches[0], repo: repo)
  
  # Debug output to help troubleshoot
  echo "Debug: Input URL = '", cleanUrl, "'"
  raise newException(ValueError, "Invalid GitHub URL format. Expected formats: https://github.com/owner/repo, github.com/owner/repo, or owner/repo")

proc makeGitHubRequest(client: HttpClient, endpoint: string, token: string = ""): JsonNode =
  ## Make authenticated GitHub API request
  var headers = newHttpHeaders([("User-Agent", "GitHub-Fork-Analyzer/1.0")])
  if token != "":
    headers["Authorization"] = "token " & token
  
  let response = client.request(endpoint, httpMethod = HttpGet, headers = headers)
  if response.status != "200 OK":
    echo "API request failed: ", response.status
    echo "Response: ", response.body
    return nil
  
  return parseJson(response.body)

proc getForks(client: HttpClient, owner: string, repo: string, token: string): seq[Fork] =
  ## Get all forks of a repository
  var forks: seq[Fork] = @[]
  var page = 1
  
  while true:
    let endpoint = &"https://api.github.com/repos/{owner}/{repo}/forks?page={page}&per_page=100"
    let response = makeGitHubRequest(client, endpoint, token)
    
    if response == nil or response.len == 0:
      break
    
    for forkJson in response:
      let fork = Fork(
        name: forkJson["name"].getStr(),
        fullName: forkJson["full_name"].getStr(),
        owner: forkJson["owner"]["login"].getStr(),
        description: forkJson["description"].getStr(""),
        stars: forkJson["stargazers_count"].getInt(),
        forks: forkJson["forks_count"].getInt(),
        lastUpdated: forkJson["updated_at"].getStr(),
        defaultBranch: forkJson["default_branch"].getStr(),
        url: forkJson["html_url"].getStr(),
        cloneUrl: forkJson["clone_url"].getStr()
      )
      forks.add(fork)
    
    page += 1
    if response.len < 100:
      break
  
  return forks

proc getCommits(client: HttpClient, owner: string, repo: string, branch: string, token: string, since: string = ""): seq[Commit] =
  ## Get commits from a repository
  var commits: seq[Commit] = @[]
  var page = 1
  
  while page <= 3: # Limit to first 3 pages to avoid rate limiting
    var endpoint = &"https://api.github.com/repos/{owner}/{repo}/commits?sha={branch}&page={page}&per_page=30"
    if since != "":
      endpoint &= &"&since={since}"
    
    let response = makeGitHubRequest(client, endpoint, token)
    
    if response == nil or response.len == 0:
      break
    
    for commitJson in response:
      let commit = Commit(
        sha: commitJson["sha"].getStr(),
        message: commitJson["commit"]["message"].getStr(),
        author: commitJson["commit"]["author"]["name"].getStr(),
        date: commitJson["commit"]["author"]["date"].getStr()
      )
      commits.add(commit)
    
    page += 1
    if response.len < 30:
      break
  
  return commits

proc categorizeCommit(message: string): tuple[isFeature: bool, isBugfix: bool, isIdea: bool] =
  ## Categorize commit based on message patterns
  let lowerMsg = message.toLower()
  
  # Feature patterns
  let featurePatterns = [
    "feat:", "feature:", "add:", "implement", "new:", "enhancement:",
    "support for", "introduce", "enable", "allow"
  ]
  
  # Bugfix patterns  
  let bugfixPatterns = [
    "fix:", "bug:", "patch:", "hotfix:", "repair", "resolve", "correct",
    "issue", "problem", "error", "crash", "failure"
  ]
  
  # Ideas/improvements patterns
  let ideaPatterns = [
    "improve:", "refactor:", "optimize:", "performance:", "cleanup:",
    "update:", "upgrade:", "modernize", "simplify", "enhance", "better"
  ]
  
  var isFeature = false
  var isBugfix = false
  var isIdea = false
  
  for pattern in featurePatterns:
    if pattern in lowerMsg:
      isFeature = true
      break
  
  for pattern in bugfixPatterns:
    if pattern in lowerMsg:
      isBugfix = true
      break
  
  for pattern in ideaPatterns:
    if pattern in lowerMsg:
      isIdea = true
      break
  
  return (isFeature: isFeature, isBugfix: isBugfix, isIdea: isIdea)

proc analyzeCommits(commits: seq[Commit]): Analysis =
  ## Analyze commits to categorize them
  var analysis = Analysis()
  
  for commit in commits:
    let category = categorizeCommit(commit.message)
    let shortMsg = commit.message.split('\n')[0] # Get first line only
    
    if category.isFeature:
      analysis.features.add(&"[{commit.author}] {shortMsg}")
    elif category.isBugfix:
      analysis.bugfixes.add(&"[{commit.author}] {shortMsg}")
    elif category.isIdea:
      analysis.ideas.add(&"[{commit.author}] {shortMsg}")
    
    analysis.commits.add(commit)
  
  return analysis

proc printAnalysis(fork: Fork, analysis: Analysis) =
  ## Print analysis results for a fork
  echo "\n" & "=".repeat(80)
  echo &"🍴 FORK: {fork.fullName}"
  echo "=".repeat(80)
  echo &"⭐ Stars: {fork.stars} | 🍴 Forks: {fork.forks}"
  echo &"📝 Description: {fork.description}"
  echo &"🔗 URL: {fork.url}"
  echo &"📅 Last Updated: {fork.lastUpdated}"
  echo &"📊 Total Commits Analyzed: {analysis.commits.len}"
  
  if analysis.features.len > 0:
    echo "\n🚀 FEATURES (" & $analysis.features.len & "):"
    echo "-".repeat(40)
    for i, feature in analysis.features:
      if i < 10: # Limit output
        echo &"  • {feature}"
      elif i == 10:
        echo &"  ... and {analysis.features.len - 10} more features"
        break
  
  if analysis.bugfixes.len > 0:
    echo "\n🐛 BUGFIXES (" & $analysis.bugfixes.len & "):"
    echo "-".repeat(40)
    for i, bugfix in analysis.bugfixes:
      if i < 10: # Limit output
        echo &"  • {bugfix}"
      elif i == 10:
        echo &"  ... and {analysis.bugfixes.len - 10} more bugfixes"
        break
  
  if analysis.ideas.len > 0:
    echo "\n💡 IDEAS & IMPROVEMENTS (" & $analysis.ideas.len & "):"
    echo "-".repeat(40)
    for i, idea in analysis.ideas:
      if i < 10: # Limit output
        echo &"  • {idea}"
      elif i == 10:
        echo &"  ... and {analysis.ideas.len - 10} more improvements"
        break
  
  if analysis.features.len == 0 and analysis.bugfixes.len == 0 and analysis.ideas.len == 0:
    echo "\n❌ No significant changes detected or commits don't follow conventional patterns"

proc printHelp() =
  echo """
GitHub Fork Analyzer - Analyze features, bugfixes, and ideas in repository forks

USAGE:
  what_the_fork <github_url> [github_token]

ARGUMENTS:
  github_url    GitHub repository URL in one of these formats:
                • https://github.com/owner/repo
                • https://github.com/owner/repo.git
                • github.com/owner/repo
                • owner/repo

  github_token  Optional GitHub personal access token for higher API rate limits
                (Without token: 60 requests/hour, With token: 5000 requests/hour)
                Get token at: https://github.com/settings/tokens

EXAMPLES:
  what_the_fork https://github.com/nim-lang/Nim
  what_the_fork nim-lang/Nim
  what_the_fork https://github.com/nim-lang/Nim ghp_your_token_here

OUTPUT:
  The tool analyzes forks and categorizes commits into:
  🚀 FEATURES      - New functionality and enhancements
  🐛 BUGFIXES      - Bug fixes and problem resolutions
  💡 IDEAS         - Improvements, refactoring, and optimizations

NOTES:
  • Analyzes up to 10 most active forks (by stars)
  • Examines up to 90 recent commits per fork
  • Uses commit message patterns to categorize changes
  • Respects GitHub API rate limits with automatic delays

For more information, visit: https://github.com
"""

proc main() =
  if paramCount() < 1 or paramStr(1) in ["-h", "--help", "help"]:
    printHelp()
    if paramCount() < 1:
      quit(1)
    else:
      quit(0)
  
  let githubUrl = paramStr(1)
  let token = if paramCount() >= 2: paramStr(2) else: ""
  
  try:
    let (owner, repo) = parseGitHubUrl(githubUrl)
    echo &"🔍 Analyzing forks of {owner}/{repo}..."
    
    let client = newHttpClient()
    defer: client.close()
    
    # Get all forks
    echo "📥 Fetching forks..."
    let forks = getForks(client, owner, repo, token)
    
    if forks.len == 0:
      echo "❌ No forks found for this repository"
      return
    
    echo &"✅ Found {forks.len} forks"
    
    # Sort forks by activity (stars + recent updates)
    var sortedForks = forks
    sortedForks.sort do (a, b: Fork) -> int:
      result = cmp(b.stars, a.stars) # Sort by stars descending
    
    # Analyze top forks (limit to prevent rate limiting)
    let maxForks = min(10, sortedForks.len)
    echo &"🔬 Analyzing top {maxForks} most active forks..."
    
    var totalFeatures = 0
    var totalBugfixes = 0
    var totalIdeas = 0
    
    for i in 0..<maxForks:
      let fork = sortedForks[i]
      echo &"\n⏳ Analyzing {fork.fullName} ({i+1}/{maxForks})..."
      
      # Get commits from the fork
      let commits = getCommits(client, fork.owner, fork.name, fork.defaultBranch, token)
      
      if commits.len > 0:
        let analysis = analyzeCommits(commits)
        printAnalysis(fork, analysis)
        
        totalFeatures += analysis.features.len
        totalBugfixes += analysis.bugfixes.len
        totalIdeas += analysis.ideas.len
      else:
        echo &"❌ Could not fetch commits for {fork.fullName}"
      
      # Small delay to be nice to GitHub API
      sleep(1000)
    
    # Summary
    echo "\n" & "=".repeat(80)
    echo "📊 SUMMARY"
    echo "=".repeat(80)
    echo &"🍴 Total Forks: {forks.len}"
    echo &"🔬 Analyzed: {maxForks}"
    echo &"🚀 Total Features Found: {totalFeatures}"
    echo &"🐛 Total Bugfixes Found: {totalBugfixes}"
    echo &"💡 Total Ideas/Improvements Found: {totalIdeas}"
    echo &"📈 Total Insights: {totalFeatures + totalBugfixes + totalIdeas}"
    
  except ValueError as e:
    echo &"❌ Error: {e.msg}"
  except Exception as e:
    echo &"❌ Unexpected error: {e.msg}"

when isMainModule:
  main()
