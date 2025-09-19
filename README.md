# MoWise - Financial planning

This is the official repository for MoWise , a platform that helps users to get detailed analytics of their Mobile Money transactions, including expenses and loans, by scanning through their mobile money messages.

## Project structure

This repository contains both the independent backend and frontend folders (not a monorepo), labeled "backend" and "frontend" respectively

## System architecture

### Where to find

We designed the high level system architecture using Miro
[Link to the design](https://miro.com/app/board/uXjVJKEMv9c=/?share_link_id=664818185790)

### Design rationale and justification

Click [here](https://lucid.app/lucidchart/9c09c617-becc-4d8f-9f93-ce407cd43702/edit?viewport_loc=-1832%2C-226%2C2563%2C1276%2C0_0&invitationId=inv_768b655d-291a-4e9c-b886-59ad4ece1c12) to see the ERD design on LucidChart (requires login)

The database design for Mowise is structured to prioritize efficient storage, relationships, and query performance. The core tables are Users, Transaction_Categories, and System Logs, with an additional junction table to link Users table to TransactionCategories.

Users store all information about users including their names, phone number, and current balance. Transactions hold the details of each mobile money operation, including amount, timestamp, reference to the People table that keeps track of all people the transactions happened with, and more transaction trackers like currency and status. Each transaction references a Transaction_Category, which shows the type of that transaction, like ELECTRICITY, WATER, Money Transfer, or other commonly recognized types. This will help in better categorization and reporting.
System_Logs record all events, including when a new transaction is recorded and whether it was successful or not. They also record when the balance of a user was updated, and the associated transaction. All these operations make auditing and history tracking fast and simple.

Finally, we have a User_Transaction_Categories junction table that makes querying the analytic reports of a user’s transactions per category easy and fast.

The design approach we used makes it easy to efficiently store all transactions, manage how information in different tables relate to each other, while allowing queries to happen faster.



## Project tracking

We are assigning and tracking tasks' progress using Notion
[Link to our scrumboard](https://www.notion.so/26825dd2b24580459a34da7ab3c8fd5a?v=26825dd2b2458083a84d000c20b0a811&source=copy_link)

## Our team - C2 Visualizers

- [Aime Cyuzuzo](https://github.com/cyuzuzo-aime)
- [Lionel Karekezi](https://github.com/karekezilionel)
- [Mordecai Nayituriki](https://github.com/nmordecai)
- [Jean Philippe Niyitegeka](https://github.com/jniyitegek)
