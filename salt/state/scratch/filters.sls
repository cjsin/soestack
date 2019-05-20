


{% set auditd = salt['grains.filter_by']({
'RedHat': { 'package': 'audit' },
'Debian': { 'package': 'auditd' },
}) %}


{% from 'lib.sls' import test %}


{% from 'lib.sls' import test with context %}

{% import 'openssl/vars.sls' as ssl  %}

{% import 'openssl/vars.sls' as ssl with context %}



{{ raise('Custom Error') }}



{% set curtime = None | strftime() %}

 {{ "2002/12/25"|strftime("%y""%y") }}
  {{ "1040814000"|strftime("%Y-%m-%d")  }}
  {{ datetime|strftime(("%u""%u"))  }}
  {{ "tomorrow"|strftime  }}

sequence
""Ensure that parsed data is a sequence.""
(no more docs)



{%- set bar = 7 %}
{%- set baz = none %}
{%- set zip = true %}
{%- set zap = 'The word of the day is "salty"' %}

{%- load_yaml as foo %}
bar: {{ bar|yaml_encode }}
baz: {{ baz|yaml_encode }}
baz: {{ zip|yaml_encode }}
baz: {{ zap|yaml_encode }}
{%- endload %}



{%- set bar = '"The quick brown fox . . ."' %}
{%- set baz = 'The word of the day is "salty".' %}

{%- load_yaml as foo %}
bar: {{ bar|yaml_dquote }}
baz: {{ baz|yaml_dquote }}
{%- endload %}



yaml_dquote


yaml_squote




{{ 'yes' | to_bool }}
{{ 'true' | to_bool }}
{{ 1 | to_bool }}
{{ 'no' | to_bool }}


{{ ['yes', 0, False, 'True'] | exactly_n_true(2) }}

{{ ['yes', False, 0, None] | exactly_one_true }}


quote  (wrap in quotes)


{{ 'abcdefabcdef' | regex_search('BC(.*)', ignorecase=True) }}
('defabcdef',)

{{ 'abcdefabcdef' | regex_match('BC(.*)', ignorecase=True) }}
None

{{ 'random' | uuid }}


{{ [1, 2, 3] | is_list }}



{{ [1, 2, 3] | is_iter }}


{{ [1, 2, 3] | min }}



{{ [1, 2, 3] | max }}


{{ [1, 2, 3] | avg }}


{{ [1, 2, 3] | union([2, 3, 4]) | join(', ') }}


{{ [1, 2, 3] | intersect([2, 3, 4]) | join(', ') }}


{{ [1, 2, 3] | difference([2, 3, 4]) | join(', ') }}


{{ [1, 2, 3] | symmetric_difference([2, 3, 4]) | join(', ') }}

{{ [1, 2, 3] | is_sorted }}


{{ [1, 2, 3] | compare_lists([1, 2, 4]) }}

{{ {'a': 'b'} | compare_lists({'a': 'c'}) }}



{{ '0xabcd' | is_hex }}
{{ 'xyzt' | is_hex }}

{{ 'abcd' | contains_whitespace }}
{{ 'ab cd' | contains_whitespace }}

{{ 'abcd' | substring_in_list(['this', 'is', 'an abcd example']) }}

{{ 5 | check_whitelist_blacklist(whitelist=[5, 6, 7]) }}
True

{{ 5 | check_whitelist_blacklist(blacklist=[5, 6, 7]) }}
False


{{ 1457456400 | date_format }}
{{ 1457456400 | date_format('%d.%m.%Y %H:%M') }}

{{ '5' | to_num }}

{{ 'wall of text' | to_bytes }}


tojson (no example)



{% set num_range = 99999999 %}
{{ num_range | random_hash }}
{{ num_range | random_hash('sha512') }}


{{ 'random' | md5 }}

{{ 'random' | sha256 }}

{{ 'random' | sha512 }}


{{ 'random' | base64_encode }}

{{ 'Z2V0IHNhbHRlZA==' | base64_decode }}


{{ 'get salted' | hmac('shared secret', 'eBWf9bstXg+NiP5AOwppB5HMvZiYMPzEM9W5YMm/AmQ=') }}


{{ 'http://jsonplaceholder.typicode.com/posts/1' | http_query }}

{{ {'a1': {'b1': {'c1': 'foo'}}, 'a2': 'bar'} | traverse('a1:b1', 'default') }}
returns {'c1': 'foo'}

{{ {'a1': {'b1': {'c1': 'foo'}}, 'a2': 'bar'} | traverse('a2:b2', 'default') }}
returns 'default'


{{ '192.168.0.1' | is_ip }}
Additionally accepts the following options:

global
link-local
loopback
multicast
private
public
reserved
site-local

{{ '192.168.0.1' | is_ip(options='loopback') }}

{{ '192.168.0.1' | is_ipv4 }}


{{ 'fe80::' | is_ipv6 }}


{{ ['192.168.0.1', 'foo', 'bar', 'fe80::'] | ipaddr }}

{{ ['192.168.0.1', 'foo', 'bar', 'fe80::'] | ipv4 }}


{{ ['192.168.0.1', 'foo', 'bar', 'fe80::'] | ipv6 }}

{{ '192.168.0.1/30' | network_hosts }}

{{ '192.168.0.1/8' | network_size }}

{{ '00:50' | gen_mac }}
Common prefixes:

00:16:3E -- Xen
00:18:51 -- OpenVZ
00:50:56 -- VMware (manually generated)
52:54:00 -- QEMU/KVM
AC:DE:48 -- PRIVATE


{{ '00:11:22:33:44:55' | mac_str_to_bytes }}


{{ 'www.google.com' | dns_check(port=443) }}


{{ '/etc/salt/master' | is_text_file }}


{{ '/etc/salt/master' | is_binary_file }}

{{ '/etc/salt/master' | is_empty_file }}

{{ '/etc/salt/master' | file_hashsum }}

{{ '/etc/salt/' | list_files | join('\n') }}

{{ '/etc/salt/' | path_join('pillar', 'device1.sls') }}


{{ 'salt-master' | which }}

{% if 1 is equalto(1) %}
    < statements >
{% endif %}
{{ [{'value': 1}, {'value': 2} , {'value': 3}] | selectattr('value', 'equalto', 3) | list }}



{% if 'a' is match('[a-b]') %}
    < statements >
{% endif %}
{{ [{'value': 'a'}, {'value': 'b'}, {'value': 'c'}] | selectattr('value', 'match', '[b-e]') | list }}
this Test supports additional optional arguments: ignorecase, multiline


regex_escape = {{ 'https://example.com?foo=bar%20baz' | regex_escape }}

unique = {{ ['foo', 'foo', 'bar'] | unique }}



# The following two function calls are equivalent.  This should work since 2014.7
{{ salt['cmd.run']('whoami') }}
{{ salt.cmd.run('whoami') }}


Context is: {{ show_full_context()|yaml(False) }}


{%- do salt.log.error('testing jinja logging') -%}


{% set hostname,domain = grains.id.partition('.')[::2] %}{{ hostname }}
{% set strings = grains.id.split('-') %}{{ strings[0] }}

{% if False %}
{{ salt['my_custom_module.my_custom_function']() }}
{{ salt.my_filters.my_jinja_filter(my_variable) }}
{% endif %}

{{ salt.dnsutil.AAAA('www.google.com') }}








##############################
default Jinja filters

abs(number)
Return the absolute value of the argument.

attr(obj, name)
Get an attribute of an object. foo|attr("bar") works like foo.bar just that always an attribute is returned and items are not looked up.

See Notes on subscriptions for more details.

batch(value, linecount, fill_with=None)
A filter that batches items. It works pretty much like slice just the other way round. It returns a list of lists with the given number of items. If you provide a second parameter this is used to fill up missing items. See this example:

<table>
{%- for row in items|batch(3, '&nbsp;') %}
  <tr>
  {%- for column in row %}
    <td>{{ column }}</td>
  {%- endfor %}
  </tr>
{%- endfor %}
</table>
capitalize(s)
Capitalize a value. The first character will be uppercase, all others lowercase.

center(value, width=80)
Centers the value in a field of a given width.

default(value, default_value=u'', boolean=False)
If the value is undefined it will return the passed default value, otherwise the value of the variable:

{{ my_variable|default('my_variable is not defined') }}
This will output the value of my_variable if the variable was defined, otherwise 'my_variable is not defined'. If you want to use default with variables that evaluate to false you have to set the second parameter to true:

{{ ''|default('the string was empty', true) }}
Aliases:	d
dictsort(value, case_sensitive=False, by='key', reverse=False)
Sort a dict and yield (key, value) pairs. Because python dicts are unsorted you may want to use this function to order them by either key or value:

{% for item in mydict|dictsort %}
    sort the dict by key, case insensitive

{% for item in mydict|dictsort(reverse=true) %}
    sort the dict by key, case insensitive, reverse order

{% for item in mydict|dictsort(true) %}
    sort the dict by key, case sensitive

{% for item in mydict|dictsort(false, 'value') %}
    sort the dict by value, case insensitive
escape(s)
Convert the characters &, <, >, ‘, and ” in string s to HTML-safe sequences. Use this if you need to display text that might contain such characters in HTML. Marks return value as markup string.

Aliases:	e
filesizeformat(value, binary=False)
Format the value like a ‘human-readable’ file size (i.e. 13 kB, 4.1 MB, 102 Bytes, etc). Per default decimal prefixes are used (Mega, Giga, etc.), if the second parameter is set to True the binary prefixes are used (Mebi, Gibi).

first(seq)
Return the first item of a sequence.

float(value, default=0.0)
Convert the value into a floating point number. If the conversion doesn’t work it will return 0.0. You can override this default using the first parameter.

forceescape(value)
Enforce HTML escaping. This will probably double escape variables.

format(value, *args, **kwargs)
Apply python string formatting on an object:

{{ "%s - %s"|format("Hello?", "Foo!") }}
    -> Hello? - Foo!
groupby(value, attribute)
Group a sequence of objects by a common attribute.

If you for example have a list of dicts or objects that represent persons with gender, first_name and last_name attributes and you want to group all users by genders you can do something like the following snippet:

<ul>
{% for group in persons|groupby('gender') %}
    <li>{{ group.grouper }}<ul>
    {% for person in group.list %}
        <li>{{ person.first_name }} {{ person.last_name }}</li>
    {% endfor %}</ul></li>
{% endfor %}
</ul>
Additionally it’s possible to use tuple unpacking for the grouper and list:

<ul>
{% for grouper, list in persons|groupby('gender') %}
    ...
{% endfor %}
</ul>
As you can see the item we’re grouping by is stored in the grouper attribute and the list contains all the objects that have this grouper in common.

Changed in version 2.6: It’s now possible to use dotted notation to group by the child attribute of another attribute.

indent(s, width=4, first=False, blank=False, indentfirst=None)
Return a copy of the string with each line indented by 4 spaces. The first line and blank lines are not indented by default.

Parameters:	
width – Number of spaces to indent by.
first – Don’t skip indenting the first line.
blank – Don’t skip indenting empty lines.
Changed in version 2.10: Blank lines are not indented by default.

Rename the indentfirst argument to first.

int(value, default=0, base=10)
Convert the value into an integer. If the conversion doesn’t work it will return 0. You can override this default using the first parameter. You can also override the default base (10) in the second parameter, which handles input with prefixes such as 0b, 0o and 0x for bases 2, 8 and 16 respectively. The base is ignored for decimal numbers and non-string values.

join(value, d=u'', attribute=None)
Return a string which is the concatenation of the strings in the sequence. The separator between elements is an empty string per default, you can define it with the optional parameter:

{{ [1, 2, 3]|join('|') }}
    -> 1|2|3

{{ [1, 2, 3]|join }}
    -> 123
It is also possible to join certain attributes of an object:

{{ users|join(', ', attribute='username') }}
New in version 2.6: The attribute parameter was added.

last(seq)
Return the last item of a sequence.

length(object)
Return the number of items of a sequence or mapping.

Aliases:	count
list(value)
Convert the value into a list. If it was a string the returned list will be a list of characters.

lower(s)
Convert a value to lowercase.

map()
Applies a filter on a sequence of objects or looks up an attribute. This is useful when dealing with lists of objects but you are really only interested in a certain value of it.

The basic usage is mapping on an attribute. Imagine you have a list of users but you are only interested in a list of usernames:

Users on this page: {{ users|map(attribute='username')|join(', ') }}
Alternatively you can let it invoke a filter by passing the name of the filter and the arguments afterwards. A good example would be applying a text conversion filter on a sequence:

Users on this page: {{ titles|map('lower')|join(', ') }}
New in version 2.7.

max(value, case_sensitive=False, attribute=None)
Return the largest item from the sequence.

{{ [1, 2, 3]|max }}
    -> 3
Parameters:	
case_sensitive – Treat upper and lower case strings as distinct.
attribute – Get the object with the max value of this attribute.
min(value, case_sensitive=False, attribute=None)
Return the smallest item from the sequence.

{{ [1, 2, 3]|min }}
    -> 1
Parameters:	
case_sensitive – Treat upper and lower case strings as distinct.
attribute – Get the object with the max value of this attribute.
pprint(value, verbose=False)
Pretty print a variable. Useful for debugging.

With Jinja 1.2 onwards you can pass it a parameter. If this parameter is truthy the output will be more verbose (this requires pretty)

random(seq)
Return a random item from the sequence.

reject()
Filters a sequence of objects by applying a test to each object, and rejecting the objects with the test succeeding.

If no test is specified, each object will be evaluated as a boolean.

Example usage:

{{ numbers|reject("odd") }}
New in version 2.7.

rejectattr()
Filters a sequence of objects by applying a test to the specified attribute of each object, and rejecting the objects with the test succeeding.

If no test is specified, the attribute’s value will be evaluated as a boolean.

{{ users|rejectattr("is_active") }}
{{ users|rejectattr("email", "none") }}
New in version 2.7.

replace(s, old, new, count=None)
Return a copy of the value with all occurrences of a substring replaced with a new one. The first argument is the substring that should be replaced, the second is the replacement string. If the optional third argument count is given, only the first count occurrences are replaced:

{{ "Hello World"|replace("Hello", "Goodbye") }}
    -> Goodbye World

{{ "aaaaargh"|replace("a", "d'oh, ", 2) }}
    -> d'oh, d'oh, aaargh
reverse(value)
Reverse the object or return an iterator that iterates over it the other way round.

round(value, precision=0, method='common')
Round the number to a given precision. The first parameter specifies the precision (default is 0), the second the rounding method:

'common' rounds either up or down
'ceil' always rounds up
'floor' always rounds down
If you don’t specify a method 'common' is used.

{{ 42.55|round }}
    -> 43.0
{{ 42.55|round(1, 'floor') }}
    -> 42.5
Note that even if rounded to 0 precision, a float is returned. If you need a real integer, pipe it through int:

{{ 42.55|round|int }}
    -> 43
safe(value)
Mark the value as safe which means that in an environment with automatic escaping enabled this variable will not be escaped.

select()
Filters a sequence of objects by applying a test to each object, and only selecting the objects with the test succeeding.

If no test is specified, each object will be evaluated as a boolean.

Example usage:

{{ numbers|select("odd") }}
{{ numbers|select("odd") }}
{{ numbers|select("divisibleby", 3) }}
{{ numbers|select("lessthan", 42) }}
{{ strings|select("equalto", "mystring") }}
New in version 2.7.

selectattr()
Filters a sequence of objects by applying a test to the specified attribute of each object, and only selecting the objects with the test succeeding.

If no test is specified, the attribute’s value will be evaluated as a boolean.

Example usage:

{{ users|selectattr("is_active") }}
{{ users|selectattr("email", "none") }}
New in version 2.7.

slice(value, slices, fill_with=None)
Slice an iterator and return a list of lists containing those items. Useful if you want to create a div containing three ul tags that represent columns:

<div class="columwrapper">
  {%- for column in items|slice(3) %}
    <ul class="column-{{ loop.index }}">
    {%- for item in column %}
      <li>{{ item }}</li>
    {%- endfor %}
    </ul>
  {%- endfor %}
</div>
If you pass it a second argument it’s used to fill missing values on the last iteration.

sort(value, reverse=False, case_sensitive=False, attribute=None)
Sort an iterable. Per default it sorts ascending, if you pass it true as first argument it will reverse the sorting.

If the iterable is made of strings the third parameter can be used to control the case sensitiveness of the comparison which is disabled by default.

{% for item in iterable|sort %}
    ...
{% endfor %}
It is also possible to sort by an attribute (for example to sort by the date of an object) by specifying the attribute parameter:

{% for item in iterable|sort(attribute='date') %}
    ...
{% endfor %}
Changed in version 2.6: The attribute parameter was added.

string(object)
Make a string unicode if it isn’t already. That way a markup string is not converted back to unicode.

striptags(value)
Strip SGML/XML tags and replace adjacent whitespace by one space.

sum(iterable, attribute=None, start=0)
Returns the sum of a sequence of numbers plus the value of parameter ‘start’ (which defaults to 0). When the sequence is empty it returns start.

It is also possible to sum up only certain attributes:

Total: {{ items|sum(attribute='price') }}
Changed in version 2.6: The attribute parameter was added to allow suming up over attributes. Also the start parameter was moved on to the right.

title(s)
Return a titlecased version of the value. I.e. words will start with uppercase letters, all remaining characters are lowercase.

tojson(value, indent=None)
Dumps a structure to JSON so that it’s safe to use in <script> tags. It accepts the same arguments and returns a JSON string. Note that this is available in templates through the |tojson filter which will also mark the result as safe. Due to how this function escapes certain characters this is safe even if used outside of <script> tags.

The following characters are escaped in strings:

<
>
&
'
This makes it safe to embed such strings in any place in HTML with the notable exception of double quoted attributes. In that case single quote your attributes or HTML escape it in addition.

The indent parameter can be used to enable pretty printing. Set it to the number of spaces that the structures should be indented with.

Note that this filter is for use in HTML contexts only.

New in version 2.9.

trim(value)
Strip leading and trailing whitespace.

truncate(s, length=255, killwords=False, end='...', leeway=None)
Return a truncated copy of the string. The length is specified with the first parameter which defaults to 255. If the second parameter is true the filter will cut the text at length. Otherwise it will discard the last word. If the text was in fact truncated it will append an ellipsis sign ("..."). If you want a different ellipsis sign than "..." you can specify it using the third parameter. Strings that only exceed the length by the tolerance margin given in the fourth parameter will not be truncated.

{{ "foo bar baz qux"|truncate(9) }}
    -> "foo..."
{{ "foo bar baz qux"|truncate(9, True) }}
    -> "foo ba..."
{{ "foo bar baz qux"|truncate(11) }}
    -> "foo bar baz qux"
{{ "foo bar baz qux"|truncate(11, False, '...', 0) }}
    -> "foo bar..."
The default leeway on newer Jinja2 versions is 5 and was 0 before but can be reconfigured globally.

unique(value, case_sensitive=False, attribute=None)
Returns a list of unique items from the the given iterable.

{{ ['foo', 'bar', 'foobar', 'FooBar']|unique }}
    -> ['foo', 'bar', 'foobar']
The unique items are yielded in the same order as their first occurrence in the iterable passed to the filter.

Parameters:	
case_sensitive – Treat upper and lower case strings as distinct.
attribute – Filter objects with unique values for this attribute.
upper(s)
Convert a value to uppercase.

urlencode(value)
Escape strings for use in URLs (uses UTF-8 encoding). It accepts both dictionaries and regular strings as well as pairwise iterables.

New in version 2.7.

urlize(value, trim_url_limit=None, nofollow=False, target=None, rel=None)
Converts URLs in plain text into clickable links.

If you pass the filter an additional integer it will shorten the urls to that number. Also a third argument exists that makes the urls “nofollow”:

{{ mytext|urlize(40, true) }}
    links are shortened to 40 chars and defined with rel="nofollow"
If target is specified, the target attribute will be added to the <a> tag:

{{ mytext|urlize(40, target='_blank') }}
Changed in version 2.8+: The target parameter was added.

wordcount(s)
Count the words in that string.

wordwrap(s, width=79, break_long_words=True, wrapstring=None)
Return a copy of the string passed to the filter wrapped after 79 characters. You can override this default using the first parameter. If you set the second parameter to false Jinja will not split words apart if they are longer than width. By default, the newlines will be the default newlines for the environment, but this can be changed using the wrapstring keyword argument.

New in version 2.7: Added support for the wrapstring parameter.

xmlattr(d, autospace=True)
Create an SGML/XML attribute string based on the items in a dict. All values that are neither none nor undefined are automatically escaped:

<ul{{ {'class': 'my_list', 'missing': none,
        'id': 'list-%d'|format(variable)}|xmlattr }}>
...
</ul>
Results in something like this:

<ul class="my_list" id="list-42">
...
</ul>
As you can see it automatically prepends a space in front of the item if the filter returned something unless the second parameter is false.

List of Builtin Tests
callable(object)
Return whether the object is callable (i.e., some kind of function). Note that classes are callable, as are instances with a __call__() method.

defined(value)
Return true if the variable is defined:

{% if variable is defined %}
    value of variable: {{ variable }}
{% else %}
    variable is not defined
{% endif %}
See the default() filter for a simple way to set undefined variables.

divisibleby(value, num)
Check if a variable is divisible by a number.

eq(a, b)
Aliases:	==, equalto
escaped(value)
Check if the value is escaped.

even(value)
Return true if the variable is even.

ge(a, b)
Aliases:	>=
gt(a, b)
Aliases:	>, greaterthan
in(value, seq)
Check if value is in seq.

New in version 2.10.

iterable(value)
Check if it’s possible to iterate over an object.

le(a, b)
Aliases:	<=
lower(value)
Return true if the variable is lowercased.

lt(a, b)
Aliases:	<, lessthan
mapping(value)
Return true if the object is a mapping (dict etc.).

New in version 2.6.

ne(a, b)
Aliases:	!=
none(value)
Return true if the variable is none.

number(value)
Return true if the variable is a number.

odd(value)
Return true if the variable is odd.

sameas(value, other)
Check if an object points to the same memory address than another object:

{% if foo.attribute is sameas false %}
    the foo attribute really is the `False` singleton
{% endif %}
sequence(value)
Return true if the variable is a sequence. Sequences are variables that are iterable.

string(value)
Return true if the object is a string.

undefined(value)
Like defined() but the other way round.

upper(value)
Return true if the variable is uppercased.

List of Global Functions
The following functions are available in the global scope by default:

range([start, ]stop[, step])
Return a list containing an arithmetic progression of integers. range(i, j) returns [i, i+1, i+2, ..., j-1]; start (!) defaults to 0. When step is given, it specifies the increment (or decrement). For example, range(4) and range(0, 4, 1) return [0, 1, 2, 3]. The end point is omitted! These are exactly the valid indices for a list of 4 elements.

This is useful to repeat a template block multiple times, e.g. to fill a list. Imagine you have 7 users in the list but you want to render three empty items to enforce a height with CSS:

<ul>
{% for user in users %}
    <li>{{ user.username }}</li>
{% endfor %}
{% for number in range(10 - users|count) %}
    <li class="empty"><span>...</span></li>
{% endfor %}
</ul>
lipsum(n=5, html=True, min=20, max=100)
Generates some lorem ipsum for the template. By default, five paragraphs of HTML are generated with each paragraph between 20 and 100 words. If html is False, regular text is returned. This is useful to generate simple contents for layout testing.

dict(**items)
A convenient alternative to dict literals. {'foo': 'bar'} is the same as dict(foo='bar').

class cycler(*items)
The cycler allows you to cycle among values similar to how loop.cycle works. Unlike loop.cycle, you can use this cycler outside of loops or over multiple loops.

This can be very useful if you want to show a list of folders and files with the folders on top but both in the same list with alternating row colors.

The following example shows how cycler can be used:

{% set row_class = cycler('odd', 'even') %}
<ul class="browser">
{% for folder in folders %}
  <li class="folder {{ row_class.next() }}">{{ folder|e }}</li>
{% endfor %}
{% for filename in files %}
  <li class="file {{ row_class.next() }}">{{ filename|e }}</li>
{% endfor %}
</ul>
A cycler has the following attributes and methods:

reset()
Resets the cycle to the first item.

next()
Goes one item ahead and returns the then-current item.

current
Returns the current item.

New in version 2.1.

class joiner(sep=', ')
A tiny helper that can be used to “join” multiple sections. A joiner is passed a string and will return that string every time it’s called, except the first time (in which case it returns an empty string). You can use this to join things:

{% set pipe = joiner("|") %}
{% if categories %} {{ pipe() }}
    Categories: {{ categories|join(", ") }}
{% endif %}
{% if author %} {{ pipe() }}
    Author: {{ author() }}
{% endif %}
{% if can_edit %} {{ pipe() }}
    <a href="?action=edit">Edit</a>
{% endif %}
New in version 2.1.

class namespace(...)
Creates a new container that allows attribute assignment using the {% set %} tag:

{% set ns = namespace() %}
{% set ns.foo = 'bar' %}
The main purpose of this is to allow carrying a value from within a loop body to an outer scope. Initial values can be provided as a dict, as keyword arguments, or both (same behavior as Python’s dict constructor):

{% set ns = namespace(found=false) %}
{% for item in items %}
    {% if item.check_something() %}
        {% set ns.found = true %}
    {% endif %}
    * {{ item.title }}
{% endfor %}
Found item having something: {{ ns.found }}
New in version 2.10.

Extensions
The following sections cover the built-in Jinja2 extensions that may be enabled by an application. An application could also provide further extensions not covered by this documentation; in which case there should be a separate document explaining said extensions.

i18n
If the i18n extension is enabled, it’s possible to mark parts in the template as translatable. To mark a section as translatable, you can use trans:

<p>{% trans %}Hello {{ user }}!{% endtrans %}</p>
To translate a template expression — say, using template filters, or by just accessing an attribute of an object — you need to bind the expression to a name for use within the translation block:

<p>{% trans user=user.username %}Hello {{ user }}!{% endtrans %}</p>
If you need to bind more than one expression inside a trans tag, separate the pieces with a comma (,):

{% trans book_title=book.title, author=author.name %}
This is {{ book_title }} by {{ author }}
{% endtrans %}
Inside trans tags no statements are allowed, only variable tags are.

To pluralize, specify both the singular and plural forms with the pluralize tag, which appears between trans and endtrans:

{% trans count=list|length %}
There is {{ count }} {{ name }} object.
{% pluralize %}
There are {{ count }} {{ name }} objects.
{% endtrans %}
By default, the first variable in a block is used to determine the correct singular or plural form. If that doesn’t work out, you can specify the name which should be used for pluralizing by adding it as parameter to pluralize:

{% trans ..., user_count=users|length %}...
{% pluralize user_count %}...{% endtrans %}
When translating longer blocks of text, whitespace and linebreaks result in rather ugly and error-prone translation strings. To avoid this, a trans block can be marked as trimmed which will replace all linebreaks and the whitespace surrounding them with a single space and remove leading/trailing whitespace:

{% trans trimmed book_title=book.title %}
    This is {{ book_title }}.
    You should read it!
{% endtrans %}
If trimming is enabled globally, the notrimmed modifier can be used to disable it for a trans block.

New in version 2.10: The trimmed and notrimmed modifiers have been added.

It’s also possible to translate strings in expressions. For that purpose, three functions exist:

gettext: translate a single string
ngettext: translate a pluralizable string
_: alias for gettext
For example, you can easily print a translated string like this:

{{ _('Hello World!') }}
To use placeholders, use the format filter:

{{ _('Hello %(user)s!')|format(user=user.username) }}
For multiple placeholders, always use keyword arguments to format, as other languages may not use the words in the same order.

Changed in version 2.5.

If newstyle gettext calls are activated (Whitespace Trimming), using placeholders is a lot easier:

{{ gettext('Hello World!') }}
{{ gettext('Hello %(name)s!', name='World') }}
{{ ngettext('%(num)d apple', '%(num)d apples', apples|count) }}
Note that the ngettext function’s format string automatically receives the count as a num parameter in addition to the regular parameters.

Expression Statement
If the expression-statement extension is loaded, a tag called do is available that works exactly like the regular variable expression ({{ ... }}); except it doesn’t print anything. This can be used to modify lists:

{% do navigation.append('a string') %}
Loop Controls
If the application enables the Loop Controls, it’s possible to use break and continue in loops. When break is reached, the loop is terminated; if continue is reached, the processing is stopped and continues with the next iteration.

Here’s a loop that skips every second item:

{% for user in users %}
    {%- if loop.index is even %}{% continue %}{% endif %}
    ...
{% endfor %}
Likewise, a loop that stops processing after the 10th iteration:

{% for user in users %}
    {%- if loop.index >= 10 %}{% break %}{% endif %}
{%- endfor %}
Note that loop.index starts with 1, and loop.index0 starts with 0 (See: For).

With Statement
New in version 2.3.

The with statement makes it possible to create a new inner scope. Variables set within this scope are not visible outside of the scope.

With in a nutshell:

{% with %}
    {% set foo = 42 %}
    {{ foo }}           foo is 42 here
{% endwith %}
foo is not visible here any longer
Because it is common to set variables at the beginning of the scope, you can do that within the with statement. The following two examples are equivalent:

{% with foo = 42 %}
    {{ foo }}
{% endwith %}

{% with %}
    {% set foo = 42 %}
    {{ foo }}
{% endwith %}
An important note on scoping here. In Jinja versions before 2.9 the behavior of referencing one variable to another had some unintended consequences. In particular one variable could refer to another defined in the same with block’s opening statement. This caused issues with the cleaned up scoping behavior and has since been improved. In particular in newer Jinja2 versions the following code always refers to the variable a from outside the with block:

{% with a={}, b=a.attribute %}...{% endwith %}
In earlier Jinja versions the b attribute would refer to the results of the first attribute. If you depend on this behavior you can rewrite it to use the set tag:

{% with a={} %}
    {% set b = a.attribute %}
{% endwith %}
Extension
In older versions of Jinja (before 2.9) it was required to enable this feature with an extension. It’s now enabled by default.

Autoescape Overrides
New in version 2.4.

If you want you can activate and deactivate the autoescaping from within the templates.

Example:

{% autoescape true %}
    Autoescaping is active within this block
{% endautoescape %}

{% autoescape false %}
    Autoescaping is inactive within this block
{% endautoescape %}
