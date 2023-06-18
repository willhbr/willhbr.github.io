---
title: "Learning Software Engineering"
---

It's an often-repeated meme that school doesn't teach you the things you need to know to get by in the working world. _"I don't know how to do taxes but at least I can solve differential equations, har har"_ is usually how they go. There is a sub-meme in Software Engineering that the things you learn at university are generally not applicable to what is needed in the industry - most jobs don't require you to be able to implement an in-place quicksort or balance a binary tree.

I generally agree with this sentiment - I now have a job and am yet to implement any kind of sorting algorithm or tree structure as part of my day-to-day responsibilities. Although I think the main problem here is comparing the Computer Science curriculum with the needs of the Software Engineering industry - like if you were to expect physics students to graduate and work as mechanical engineers[^bad-analogy].

[^bad-analogy]: This may be a bad analogy, I have not studied physics since my first year of university and don't really know what mechanical engineers do day-to-day. But I'm sure you get the gist.

The thing that I find frustrating is the distain towards group projects - whether it's cramming all the work in at the last minute, group members not pulling their weight, etc. No one likes group projects, and can you blame them? They're nothing like working in the real world. [This blog post by James Hood](http://jlhood.com/bad-habits-we-learn-in-school/) gives a good comparison of what it's like doing work at school vs in industry. It's not aimed specifically at group projects, but this summary shows how James perceives group projects:

> "Sure, we may get the occasional group project, however that’s generally the exception. In these group projects, it’s not uncommon for one or two individuals to end up doing most of the work while the rest of the team coasts."

The core difference is that when working in the industry, deadlines either aren't concrete - and if they are and you're not on track to meet them, a good team will work out how to work together and reach it - on top of that the scope can be changed in collaboration with the client or project owner if the deadline can't be met. And unless you work in the games industry where a [death march](https://en.m.wikipedia.org/wiki/Death_march_(project_management)) is the accepted project management practice, you should have some kind of work/life balance where you are not spending every moment of your day pushing to complete the project.

What I think is the problem with group projects is that they need to go big or not bother - especially projects done in smaller groups or in pairs. If you give a small project to a pair of students, it's quite likely that one of them can just get on a roll and churn through the majority of the project. I have done this and it's not good for either party.

This is exacerbated when the project doesn't have N obvious parts that can be allocated one to each team member. If the parts have to interact then the team member that does theirs first or makes the most used part will become the go-to person in working out how all the other parts should integrate - doing more work than anyone else.

This is basically distilled down to "you research it and I'll write the report" - but then the person that does the research has to write a report to transfer the knowledge of what they researched. Just replace "research" and "write report" with the components of the project.

What makes a worthwhile group project for software engineers? In the third year of my degree (which was four years in total) we had a group project that lasted the whole year. I think almost everyone in the class learnt a lot about working successfully in a team, as well as learning software engineering skills that you don't pick up working by yourself.

The course outline looks like this:

> The Software Engineering group project gives students in-depth experience in developing software applications in groups. Participants work in groups to develop a complex real application. At the end of this course you will have practiced the skills required to be a Software Engineer in the real world, including gaining the required skills to be able to develop complex applications, dealing with vague (and often conflicting) customer requirements, working under pressure and being a valuable member of a software development team.

There are a lot of small things that make this course work, but I'm just going to mention a few of the most significant:

Firstly having a massive project that is too big for one person to do or to cram in at the start of the year, it is always big enough that you can't see the whole scope and how things fit together until you've finished the initial parts - this forces the team to work sustainably and discourages cramming it all at the last minute or trying to get everything out of the way. This should guide the team to get into a consistent rhythm.

The team should reflect the size of an industry software engineering team - about six to ten people. I think seven is a good size - it is small enough that everyone can keep up-to-date with the rest of the team, but big enough to produce a sizeable amount of work throughout the year. 

Instead of having a single deadline at the end of the project where the team dumps a load of work and promptly forgets about it, the team should at least be getting feedback on how their development process is improving. Ideally, teachers would be able to do significant analysis into how the team is working - incorporating both data gathered from the codebase, the development process, and subjective feedback from students.

> This analysis is a massive amount of work, and is hard to get right - my final year project was to improve the analysis of code. I didn't improve it an awful lot but learnt a lot about syntax trees, [Gumtree](https://github.com/GumTreeDiff/gumtree) and Git.

The team should be marked on their ability to work as a team, and improve their process over the year - as well as the quality of the actual project work that they complete. This gives them the ability to improve their development process - perhaps at the expense of number of features - but hopefully becoming more sustainable and improving other "soft skills".

This kind of work also has the added benefit of teaching students how to deal with typical industry tools, like getting into a Git merge hell, opening a bunch of bugs in an issue tracker and ignoring them for months, dutifully splitting all their work into stories and tasks and never updating them as the work gets done, receiving panicked Slack messages late at night then working out whether you can get away with ignoring them, and realising that time tracking is a punishment that no one deserves before fudging their timesheet at the end of the day. Proper valuable skills that software engineers use every day.

Of course this means that if you're planning a project that is only a few weeks long and doesn't make up much of the marks in the course, it probably shouldn't be a given out as a group project.

Just like computer science is more more than just writing programs - you learn about algorithms, data structures, complexity analysis, etc - software engineering is not just computer science. Learning to be a software engineer also includes the ever-dreaded soft-skills and learning how to actually put together a piece of software that will be used by other people. And so just like in computer science there is far more than just learning how to program, software engineering must be far more than just learning computer science with other people.
