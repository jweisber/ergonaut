# Ergonaut – Peer Review on Rails

Ergonaut is a peer review management system, similar to [OJS](https://pkp.sfu.ca/ojs/) or [ScholarOne](http://scholarone.com/products/manuscript/). It was created for the open access philosophy journal [*Ergo*](http://www.ergophiljournal.org), where it oversees the peer review process.

Adhering to the ["Do One Thing Well"](https://en.wikipedia.org/wiki/Unix_philosophy#Do_One_Thing_and_Do_It_Well) philosophy, Ergonaut is designed specifically for keeping the peer review process running smoothly. To that end it is:

- simple, attractive, and easy to use,
- zealous about reminding referees and editors to keep things on schedule, and
- strictly a peer review system. Unlike OJS, a publication platform is not included.

Also unlike OJS, Ergonaut serves one journal per instance rather than share one database across many journals.


# Feature Summary


## Two-Tiered Editorial Structure

There are two kinds of editors: managing editors and handling editors.

- Managing editors assign submissions to handling editors and, eventually, finalize their decisions.	
- Handling editors read submissions, solicit referee reports, and submit their decisions for approval by the managing editors.

	
## Triple-Anonymous Review

The peer review process is strictly anonymous to minimize bias.

- Handling editors are not shown authors' identities.
- Referees are not shown authors' identities.
- Authors are not shown referees' identities or the handling editor's identity.


## Reminders & Notifications

Frequent email reminders and notifications keep everyone on task and on schedule.

- Referees are emailed when they fail to respond to a request for a review, when their review will be due soon, and when their review is overdue.
- Handling editors are emailed when a submission needs referees assigned, when a request for a review is accepted/declined, when a review is completed, and when a decision is overdue.
- Managing editors are emailed when a submission needs a handling editor assigned, and when a decision needs approval.
- Editors are cc'ed on all correspondence related to submissions they are responsible for (except for correspondence that would compromise the anonymity of the review process; see below).


## Transparency

Ergonaut keeps authors and referees informed about the statuses and fates of submissions they're involved with.

- Authors can track the activity on their submissions in detail:
	- whether a handling editor has been assigned,
	- when a referee is contacted,
	- when and how they responded,
	- when their report is due, and
	- if/when their report is complete.
- Referee reports are shared among all referees who worked on a submission, once a decision is reached.		

Statistics about the peer review process are publicly viewable in a detailed, graphical display. These include:

- Number of submissions per year, number of resubmissions, number of withdrawn submissions, etc.
- % of submissions rejected without external review, % rejected with external review, % accepted, etc.
- Average time to decision: for desk rejected submissions, for externally reviewed submissions, and for all submissions overall.
- Number of submissions in each topic (e.g. ethics, metaphysics, logic, etc.)