"""Main module."""
import os
import re

import fire

START_WORDS = ['select', 'from', 'join', 'left join', 'right join', 'group', 'with', 'where', 'order', 'having']
SPECIAL_WORDS = ['select', 'from', 'group', 'with', 'as', 'where', 'and', 'between', 'having', 'order', 'by']
SPECIAL_WORDS = SPECIAL_WORDS + START_WORDS
SPECIAL_FUNCS = ['date']
NEWLINE_WORDS = ['select', 'distinct']
NEWLINE_CHARACTERS = [',']
TAB = '    '
TWOTABS_WORDS = ['else', 'when']


def prettysql(filename=None, filename_out=None):
    """Make sql files pretty."""
    if filename is None and filename_out is None:
        filenames = os.listdir()
        filenames = [v for v in filenames if v.endswith('.sql')]
        for filename in filenames:
            prettysql_file(filename)
    else:
        prettysql_file(filename, filename_out)


def prettysql_file(filename, filename_out=None):
    """Make sql file pretty."""
    if filename_out is None:
        filename_out = filename
    print(f"{filename} -> {filename_out}")
    with open(filename, 'r') as f:
        sql = f.read()
    special_words = [v.upper() for v in SPECIAL_WORDS]
    start_words = [v.upper() for v in START_WORDS]
    special_funcs = [v.upper() for v in SPECIAL_FUNCS]
    newline_words = [v.upper() for v in NEWLINE_WORDS]
    newline_characters = [v.upper() for v in NEWLINE_CHARACTERS]
    twotabs_words = [v.upper() for v in TWOTABS_WORDS]

    while ' \n' in sql:
        sql = sql.replace(' \n', '\n')

    for special_word in special_words:
        pattern = re.compile(f"{special_word} ", re.IGNORECASE)
        sql = pattern.sub(f"{special_word} ", sql)
    for special_word in special_words:
        pattern = re.compile(f"{special_word}\\n", re.IGNORECASE)
        sql = pattern.sub(f"{special_word}\n", sql)
    for start_word in start_words:
        sql = sql.replace(f"{start_word}\n", f"{start_word} ")
    for special_func in special_funcs:
        pattern = re.compile(f"{special_func}\(", re.IGNORECASE)
        sql = pattern.sub(f"{special_func}(", sql)
    for newline_word in newline_words:
        sql = sql.replace(f"{newline_word} ", f"{newline_word}\n")
    for newline_character in newline_characters:
        sql = sql.replace(newline_character, f'{newline_character}\n')
    for twotabs_word in twotabs_words:
        sql = sql.replace(f"{twotabs_word}\n", f"{twotabs_word} ")
    while '  ' in sql:
        sql = sql.replace('  ', ' ')

    sql_lines = sql.split('\n')
    sql_lines_tmp = []
    for sql_line in sql_lines:
        while sql_line.startswith(' '):
            sql_line = sql_line[1:]
        if any([sql_line.startswith(s) for s in twotabs_words]):
            sql_line = TAB + sql_line
        startwith_startword = any([sql_line.startswith(s) for s in start_words])
        if ' AS (' in sql_line:
            startwith_startword = True
        if not startwith_startword:
            sql_line = TAB + sql_line

        if sql_line.split() != []:
            sql_lines_tmp += [sql_line]
    sql_lines = sql_lines_tmp
    sql = '\n'.join(sql_lines)

    with open(filename_out, 'w') as f:
        f.write(sql)


def main():
    """Execute main program."""
    fire.Fire(prettysql)


if __name__ == "__main__":
    main()
