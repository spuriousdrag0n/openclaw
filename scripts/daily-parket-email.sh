#!/bin/bash
# Daily email to Federal Prosecutor's Office - Simon Tadros Case

RECIPIENT="parquet.federal@just.fgov.be"
SUBJECT="Simon Tadros - Urgent: Case Reassignment and Administrative Failure"
ACCOUNT="spuriousdragon@gmail.com"

BODY="To Whom It May Concern,

I am writing in disbelief after being informed that the chamber of the Court of Appeals designated to hear my case has been dissolved due to the absence of a clerk.

This development is not a minor administrative inconvenience. It is a serious institutional failure.

For 2.4 years, the Belgian state mobilized its full machinery against me:

- Coordination with Europol
- International arrest
- Extradition
- Six months of pre-trial detention
- A prolonged federal investigation
- Severe reputational and financial damage

After all of this, I was fully acquitted due to lack of hard evidence.

For 2.4 years, the system functioned efficiently when it was prosecuting me.

Now, when the matter concerns appeal, accountability, and compensation for the irreversible damage done, the chamber responsible for hearing my case no longer exists because of an administrative deficiency.

This raises serious questions about the stability and reliability of the judicial process.

The rule of law cannot operate selectively. It cannot be strong when accusing and fragile when correcting itself. The dissolution of a judicial chamber due to staffing issues undermines confidence in institutional continuity and due process.

During these 2.4 years, I endured the destruction of my professional standing, financial strain, and immense psychological pressure on my family. I lost both of my parents during this prolonged ordeal — a period marked by stress and uncertainty that no family should have to endure.

Justice delayed is already injustice. Justice obstructed by administrative collapse is something far more troubling.

I respectfully request:

1. Immediate clarification regarding the reassignment of my case.
2. A concrete timeline for continuation of appellate proceedings.
3. Assurance that this administrative failure will not further delay resolution and compensation.

A dissolved chamber does not dissolve responsibility.

I expect a prompt and transparent response.

Sincerely,
Simon Tadros"

/usr/local/bin/gog gmail send \
  --account "$ACCOUNT" \
  --to "$RECIPIENT" \
  --subject "$SUBJECT" \
  --body "$BODY"
