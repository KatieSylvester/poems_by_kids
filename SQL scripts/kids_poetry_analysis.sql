/* SQL exploration of Kids Poetry database tables */

SELECT * FROM poem LIMIT 10;
SELECT * FROM author LIMIT 10;
SELECT * FROM gender LIMIT 10;
SELECT * FROM grade LIMIT 10;
SELECT * FROM poem_emotion LIMIT 10;
SELECT * FROM emotion LIMIT 10;


/* Total number of poets per grade and broken out by gender */
SELECT
	a.grade_id,
	COUNT(CASE WHEN g.name='Female' THEN 1 END) AS female,
	COUNT(CASE WHEN g.name='Male' THEN 1 END) AS male,
	COUNT(CASE WHEN g.name='Ambiguous' THEN 1 END) AS anonymous,
	COUNT(CASE WHEN g.name='NA' THEN 1 END) AS NA,
	COUNT(CASE WHEN g.name IS NULL THEN 1 END) AS null,
	COUNT(a.id) AS total_poets
FROM author AS a
LEFT JOIN gender as g
ON a.gender_id=g.id
GROUP BY a.grade_id
ORDER BY grade_id


/* AUTHOR GENDER DEMOGRAPHICS
Total percentage of poets per gender for all grades combined */
SELECT
	ROUND(((100*COUNT(CASE WHEN g.name='Female' THEN 1 END)::DECIMAL/COUNT(a.id))::DECIMAL),1) AS Female,
	ROUND(((100*COUNT(CASE WHEN g.name='Male' THEN 1 END)::DECIMAL/COUNT(a.id))::DECIMAL),1) AS Male,
	ROUND(((100*COUNT(CASE WHEN g.name='Ambiguous' THEN 1 END)::DECIMAL/COUNT(a.id))::DECIMAL),1) AS Ambiguous,
	ROUND(((100*COUNT(CASE WHEN g.name='NA' THEN 1 END)::DECIMAL/COUNT(a.id))::DECIMAL),1) AS NA,
	ROUND(((100*COUNT(CASE WHEN g.name IS NULL THEN 1 END)::DECIMAL/COUNT(a.id))::DECIMAL),1) AS Null_Value,
	COUNT(a.id) AS total_poets
FROM author AS a
LEFT JOIN gender as g
ON a.gender_id=g.id


/* EMOTION INTENSITY
Average intensity and average character count per emotion category */
SELECT
	e.name,
		ROUND(AVG(pe.intensity_percent),1) AS avg_intensity_percent,
	ROUND(AVG(p.char_count),1) AS avg_char_count
FROM emotion AS e
JOIN poem_emotion AS pe
ON e.id=pe.emotion_id
JOIN poem AS p
ON p.id=pe.poem_id
GROUP BY e.name
ORDER BY avg_char_count DESC;


/* The Top 5 most intense poems for joy and anger
as well as their character count and if the character count is above or below the 
average character count for that emotion */
WITH emotion_groups AS (
		SELECT
			e.name,
			ROUND(AVG(p.char_count),2) AS avg_char_count
			--ROUND(AVG(pe.intensity_percent),2) AS avg_intensity_percent
		FROM emotion AS e
		JOIN poem_emotion AS pe
		ON e.id=pe.emotion_id
		JOIN poem AS p
		ON p.id=pe.poem_id
		GROUP BY e.name
		ORDER BY avg_char_count DESC),
joy AS (
	SELECT p.id,'Joy' AS category,p.title, p.text, pe.intensity_percent, p.char_count,
		CASE WHEN p.char_count >(SELECT avg_char_count FROM emotion_groups WHERE name='Joy') THEN 'above avg char count'
			WHEN p.char_count =(SELECT avg_char_count FROM emotion_groups WHERE name='Joy') THEN 'exactly avg char count'
			ELSE 'below avg char count' END AS char_count_comparison
	FROM poem AS p
	LEFT JOIN poem_emotion AS pe
	ON p.id=pe.poem_id
	WHERE pe.emotion_id = (SELECT id FROM emotion WHERE name='Joy')
	ORDER BY intensity_percent DESC
	LIMIT 5),
anger AS (SELECT p.id,'Anger' AS category,p.title, p.text, pe.intensity_percent, p.char_count,
		CASE WHEN p.char_count >(SELECT avg_char_count FROM emotion_groups WHERE name='Anger') THEN 'above avg char count'
			WHEN p.char_count =(SELECT avg_char_count FROM emotion_groups WHERE name='Anger') THEN 'exactly avg char count'
			ELSE 'below avg char count' END AS char_count_comparison
	FROM poem AS p
	LEFT JOIN poem_emotion AS pe
	ON p.id=pe.poem_id
	WHERE pe.emotion_id = (SELECT id FROM emotion WHERE name='Anger')
	ORDER BY intensity_percent DESC
	LIMIT 5)
SELECT * FROM joy
UNION ALL
SELECT * FROM anger;


/* EMOTION CONTENT BY GRADE LEVEL
percentage of emotion content for each grade */
SELECT
	a.grade_id AS grade_level,
	CONCAT((ROUND((100*(COUNT(CASE WHEN e.name='Anger' THEN 1 END)::DECIMAL/COUNT(e.name))::DECIMAL),1)),'%') AS anger,
	CONCAT((ROUND((100*(COUNT(CASE WHEN e.name='Fear' THEN 1 END)::DECIMAL/COUNT(e.name))::DECIMAL),1)),'%') AS fear,
	CONCAT((ROUND((100*(COUNT(CASE WHEN e.name='Joy' THEN 1 END)::DECIMAL/COUNT(e.name))::DECIMAL),1)),'%') AS sadness,
	CONCAT((ROUND((100*(COUNT(CASE WHEN e.name='Sadness' THEN 1 END)::DECIMAL/COUNT(e.name))::DECIMAL),1)),'%') AS joy
FROM emotion AS e
JOIN poem_emotion AS pe
ON e.id=pe.emotion_id
JOIN poem AS p
ON p.id=pe.poem_id
JOIN author as A
ON p.author_id=a.id
GROUP BY a.grade_id
ORDER BY a.grade_id


/* After scanning the poem texts, I selected several key words (mom, school, cat and friend)
that were frequently seen words.  This exploration looks at how often those words are used 
(poem count) as well as the average intensity and average character count of the poem's 
that include the word. */
WITH mom AS (
	SELECT poem.id, char_count, intensity_percent
	FROM poem 
	LEFT JOIN poem_emotion ON poem.id=poem_emotion.poem_id
	WHERE text ilike '%mom%'),
cat AS (
	SELECT poem.id, char_count, intensity_percent
	FROM poem 
	LEFT JOIN poem_emotion ON poem.id=poem_emotion.poem_id
	WHERE text ilike '%cat%'),
friend AS (
	SELECT poem.id, char_count, intensity_percent
	FROM poem 
	LEFT JOIN poem_emotion ON poem.id=poem_emotion.poem_id
	WHERE text ilike '%friend%'),
school AS (
	SELECT poem.id, char_count, intensity_percent
	FROM poem 
	LEFT JOIN poem_emotion ON poem.id=poem_emotion.poem_id
	WHERE text ilike '%school%'),
cat2 AS (
	SELECT
		'cat' AS key_word, 
		COUNT(id) AS poem_count, 
		ROUND(AVG(intensity_percent),2) AS avg_intensity,
		ROUND(AVG(char_count),2) AS avg_char_count
	FROM cat GROUP BY key_word),
mom2 AS (
	SELECT 
		'mom' AS key_word, 
		COUNT(id) AS poem_count, 
		ROUND(AVG(intensity_percent),2) AS avg_intensity,
		ROUND(AVG(char_count),2) AS avg_char_count
	FROM mom GROUP BY key_word),
friend2 AS (
	SELECT
		'friend' AS key_word, 
		COUNT(id) AS poem_count, 
		ROUND(AVG(intensity_percent),2) AS avg_intensity,
		ROUND(AVG(char_count),2) AS avg_char_count
	FROM friend GROUP BY key_word),
school2 AS (
	SELECT 
		'school' AS key_word, 
		COUNT(id) AS poem_count, 
		ROUND(AVG(intensity_percent),2) AS avg_intensity,
		ROUND(AVG(char_count),2) AS avg_char_count
	FROM school GROUP BY key_word)
SELECT *
FROM cat2
UNION ALL
SELECT *
FROM mom2
UNION ALL
SELECT *
FROM friend2
UNION ALL
SELECT *
FROM school2;


	