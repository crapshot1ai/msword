if(NOT DEFINED INPUT)
    message(FATAL_ERROR "INPUT was not specified")
endif()

if(NOT DEFINED OUTPUT)
    message(FATAL_ERROR "OUTPUT was not specified")
endif()

if(NOT EXISTS "${INPUT}")
    message(FATAL_ERROR "Input file does not exist: ${INPUT}")
endif()

file(STRINGS "${INPUT}" MENUHELP_LINES)

set(MENUHELP_ENTRIES "")

foreach(line IN LISTS MENUHELP_LINES)

    # MKCMD output format:
    #
    # x,      "Some help text"
    #
    # Ignore comments and other lines.
    if(line MATCHES "^[ \t]*x,[ \t]*\"(.*)\"[ \t]*$")

        set(text "${CMAKE_MATCH_1}")

        # Escape backslashes and quotes for a C string literal.
        string(REPLACE "\\" "\\\\" text "${text}")
        string(REPLACE "\"" "\\\"" text "${text}")

        string(APPEND MENUHELP_ENTRIES
            "    \"${text}\",\n"
        )
    endif()

endforeach()

file(WRITE "${OUTPUT}"
"/* Automatically generated from MENUHELP.TXT. */\n"
"#pragma once\n"
"\n"
"#ifdef OPUS_X64\n"
"\n"
"static const char * const opus_x64_menu_help_strings[] =\n"
"{\n"
"${MENUHELP_ENTRIES}"
"};\n"
"\n"
"#define OPUS_X64_MENU_HELP_COUNT \\\n"
"    (sizeof(opus_x64_menu_help_strings) / sizeof(opus_x64_menu_help_strings[0]))\n"
"\n"
"#define OPUS_X64_MENU_HELP_STRING(i) \\\n"
"    (((unsigned)(i) < OPUS_X64_MENU_HELP_COUNT) ? \\\n"
"        opus_x64_menu_help_strings[(unsigned)(i)] : \"\")\n"
"\n"
"#else\n"
"\n"
"/* Historical non-x64 build consumes the original generated representation. */\n"
"\n"
"#endif\n"
)