---
title: Testing GitLab CI
---

During my internship this summer I found myself pining for a continuous integration server. The project I was working on had a massive set of [Cucumber tests](https://github.com/cucumber/cucumber-rails). The only problem was that they took 40 minutes to run completely, which is a bit too much of a pain to actually run them regularly on a local machine. Last semester for my software engineering group project, we were given Jenkins servers to run our tests on - this enforced the habit of keeping the tests up to date and fixing anything that breaks them.

I started looking around out of curiosity to see what else there was apart from Jenkins, which was not the most friendly thing to set up at the start of the project. After a little search I came across [GitLab CI](https://about.gitlab.com/gitlab-ci/) which integrates right into GitLab (obviously) and is written in [Go](https://golang.org) which makes it quite cool right off the bat.

GitLab CI can be the simplest build server that you could imagine - it can be easily set to just run a shell script when a commit is pushed, and if the exit status is zero it succeeded, if it's non-zero then it failed. This basically means that you don't _have_ to learn a new configuration syntax to do anything (you can, but it's definitely not needed). If you can run your tests from the command line, you're good to go.

Once it has been set up, every commit to the repo will trigger a build on your server and the result will be displayed in the 'builds' tab of GitLab and when you view the commit. This can be done with either GitLab.com or a different hosted instance of GitLab.

Full installation instructions for CI Runner are on [GitLab's website]. However it's as simple installing a package and running the setup (Instructions for Ubuntu, other distros on [GitLab's website])

```shell
# Add the source to apt-get:
curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-ci-multi-runner/script.deb.sh | sudo bash
# Install the runner package
sudo apt-get install gitlab-ci-multi-runner
# Run the setup
gitlab-ci-multi-runner register
```

> The instructions say to run the last command with sudo, but when I did this my config file was set to be in `/etc/gitlab-runner/config.toml` rather than the expected `~/.gitlab-runner/config.toml`.

The register command sets up a runner to point to a certain GitLab url (either GitLab.com or your custom instance) and the token needed to pull your code. I setup mine with:

    URL: https://gitlab.com/ci
    Token: ~~ secret token ~~ # Accessed in the main project settings
    Description: Test runner
    Executor: shell

I made a quick branch on [one of my projects](https://github.com/JavaNut13/WORM) that has fair number of unit tests that are easily run. All I had to do was add a `.gitlab-ci.yml` file:

```yaml
maven-package:
  script: "mvn package -B"
```

`maven-package` is the name of the build process, and the `script` key denotes either a single bash command or a list of commands. Once this was pushed to GitLab a build immediately started.

And failed instantly. Thankfully a full log gets output to the web interface and I could see that the runner was getting confused trying to load up a Docker instance, even though I didn't configure that. So once I'd found the config file location (which wasn't where I expected, as I mentioned before) and deleted all the entries apart from the main `[[runners]]` section (getting rid of the `[[runners.docker]]` section probably would have been enough). Once I'd made this change the build completed successfully.

Right now I'm very impressed with the ease of setting up a GitLab CI Runner and will definitely use one in the future (especially if I get a [scooter computer](https://blog.codinghorror.com/the-scooter-computer/)) for the odd occasion that I write unit tests. However if I did set up a CI server I would want to make sure the gitlab-runner user had as few permissions as possible - probably only able to read or write within their own home directory - so that the chance of breaking my setup is reduced.

[Gitlab's website]: https://gitlab.com/gitlab-org/gitlab-ci-multi-runner/blob/master/docs/install/linux-repository.md
