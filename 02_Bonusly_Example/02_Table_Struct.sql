CREATE TABLE bly.Bonuses (
	[id] CHAR(24) NOT NULL,
	[parent_bonus_id] CHAR(24) NULL,
	[created_at] VARCHAR(25) NULL,
	[reason] VARCHAR(max) NULL,
	[reason_html] VARCHAR(max) NULL,
	[amount] VARCHAR(40) NULL,
	[amount_with_currency] VARCHAR(10) NULL,
	[value] VARCHAR(30) NULL,
	[via] VARCHAR(10) NULL,
	[family_amount] VARCHAR(40) NULL
);

GO

CREATE TABLE bly.BonusUsersGivers (
	[bonus_id] CHAR(24) NOT NULL,
	[user_id] CHAR(24) NOT NULL,
);

GO

CREATE TABLE bly.BonusUsersReceivers (
	[bonus_id] CHAR(24) NOT NULL,
	[user_id] CHAR(24) NOT NULL,
);

GO

CREATE TABLE bly.Users (
	[id] CHAR(24) NOT NULL,
	[short_name] VARCHAR(30) NULL,
	[display_name] VARCHAR(30) NULL,
	[username] VARCHAR(30) NULL,
	[email] VARCHAR(30) NULL,
	[path] VARCHAR(39) NULL,
	[full_pic_url] VARCHAR(150) NULL,
	[profile_pic_url] VARCHAR(150) NULL,
	[first_name] VARCHAR(30) NULL,
	[last_name] VARCHAR(30) NULL,
	[created_at] VARCHAR(25) NULL,
	[last_active_at] VARCHAR(25) NULL,
	[external_unique_id] VARCHAR(50) NULL,
	[budget_boost] VARCHAR(5) NULL,
	[user_mode] VARCHAR(6) NULL,
	[country] VARCHAR(2) NULL,
	[time_zone] VARCHAR(25) NULL,
	[can_give] VARCHAR(5) NULL,
	[earning_balance] VARCHAR(40) NULL,
	[earning_balance_with_currency] VARCHAR(40) NULL,
	[lifetime_earnings] VARCHAR(40) NULL,
	[lifetime_earnings_with_currency] VARCHAR(40) NULL,
	[can_receive] VARCHAR(5) NULL,
	[giving_balance] VARCHAR(40) NULL,
	[giving_balance_with_currency] VARCHAR(10) NULL,
	[status] VARCHAR(9) NULL,
	[department] VARCHAR(25) NULL,
	[location] VARCHAR(15) NULL
);

GO

CREATE TABLE bly.HashtagsCompany (
	hashtag VARCHAR(30) NOT NULL
);

GO

CREATE TABLE bly.HashtagsSuggested (
	hashtag VARCHAR(30) NOT NULL
);

GO

CREATE TABLE bly.HashtagsTrending (
	hashtag VARCHAR(30) NOT NULL
);

GO

CREATE TABLE bly.Rewards (
	[id] CHAR(24) NOT NULL,
	[type] VARCHAR(11) NOT NULL,
	[type_name] VARCHAR(25) NULL,
	[reward_name] VARCHAR(75) NULL,
	[image_url] VARCHAR(200) NULL,
	[minimum_display_price] VARCHAR(15) NULL,
	[description_text] VARCHAR(500) NULL,
	[description_html] VARCHAR(500) NULL,
	[disclaimer_html] VARCHAR(500) NULL,
	[warning] VARCHAR(1000) NULL,
	[denomination_name] VARCHAR(75) NULL,
	[price] VARCHAR(40) NULL,
	[display_price] VARCHAR(13) NULL,
	[available] VARCHAR(5) NULL
);

GO

