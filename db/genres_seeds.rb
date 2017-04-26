Genre.delete_all()

# genres = [ "Architecture",
#         "Artifacts", "Bibliography",
#         "Collection", "Criticism", "Drama",
#         "Education", "Ephemera", "Fiction",
#         "History", "Leisure", "Letters",
#         "Life Writing", "Manuscript", "Music",
#         "Nonfiction", "Paratext", "Periodical",
#         "Philosophy", "Photograph", "Poetry",
#         "Religion", "Review", "Science",
#         "Translation", "Travel",
#         "Visual Art", "Citation",
#         "Book History", "Family Life", "Folklore",
#         "Humor", "Law", "Reference Works", "Sermon" ]

# note: these genres were already out of date pre 3/17 reindex

genres = ["Advertisement", "Animation", "Bibliography",
          "Catalog", "Chronology", "Citation",
          "Collection", "Correspondence", "Criticism",
          "Drama", "Ephemera", "Essay", "Fiction",
          "Film, Documentary", "Film, Experimental", "Film, Narrative", "Film, Other",
          "Historiography", "Interview", "Life Writing",
          "Liturgy", "Musical Analysis", "Music, Other",
          "Musical Work", "Musical Score", "Nonfiction",
          "Paratext", "Performance", "Philosophy",
          "Photograph", "Political Statement", "Poetry",
          "Religion", "Reference Works", "Review",
          "Scripture", "Sermon", "Speech", "Translation",
          "Travel Writing", "Unspecified", "Visual Art"]

genres.each { |genre|
	Genre.create!({ :name => genre })
}
