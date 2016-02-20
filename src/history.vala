/*
 * Copyright (C) 2011-2012 Robert Ancell
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 2 of the License, or (at your option) any later
 * version. See http://www.gnu.org/copyleft/gpl.html the full text of the
 * license.
 */

public class History
{
    public string filename;
	public string statFileName;
    public List<HistoryEntry> entries;
	public List<StatEntry> statEntries;

    public signal void entry_added (HistoryEntry entry);

    public History (string filename,string statFileName)
    {
        this.filename = filename;
		this.statFileName=statFileName;
        entries = new List<HistoryEntry> ();
		statEntries = new List<StatEntry> ();
	}

    public void add (HistoryEntry entry)
    {
        entries.append (entry);
        entry_added (entry);
    }

	public StatEntry? find_stat(uint width,uint height,uint n_mines)
	{
		foreach (var stat in statEntries)
		{
			if (stat.width==width && stat.height==height && stat.n_mines==n_mines)
			{
				return stat;
			}
		}
        return null;
	}

	public void addWin(uint width,uint height,uint n_mines)
	{
		StatEntry? stat=find_stat(width,height,n_mines);
		if (stat!=null) 
		{
			stat.wins++;
		} else {
			statEntries.append(new StatEntry(width,height,n_mines,1,0));
		}
	}
	
	public void addLose(uint width,uint height,uint n_mines)
	{
		StatEntry? stat=find_stat(width,height,n_mines);
        if (stat!=null)
		{
			stat.loses++;
		} else {
			statEntries.append(new StatEntry(width,height,n_mines,0,1));
		}
	}

    public void load ()
    {
        entries = new List<HistoryEntry> ();

        var contents = "";
        try
        {
            FileUtils.get_contents (filename, out contents);
        }
        catch (FileError e)
        {
            if (!(e is FileError.NOENT))
                warning ("Failed to load history: %s", e.message);
            return;
        }

        foreach (var line in contents.split ("\n"))
        {
            var tokens = line.split (" ");
            if (tokens.length != 5)
                continue;

            var date = parse_date (tokens[0]);
            if (date == null)
                continue;
            var width = int.parse (tokens[1]);
            var height = int.parse (tokens[2]);
            var n_mines = int.parse (tokens[3]);
            var duration = int.parse (tokens[4]);

            add (new HistoryEntry (date, width, height, n_mines, duration));
        }

		statEntries = new List<StatEntry> ();

        contents = "";
        try
        {
            FileUtils.get_contents (statFileName, out contents);
        }
        catch (FileError e)
        {
            if (!(e is FileError.NOENT))
                warning ("Failed to load statistic: %s", e.message);
            return;
        }

        foreach (var line in contents.split ("\n"))
        {
            var tokens = line.split (" ");
            if (tokens.length != 5)
                continue;

            var width = int.parse (tokens[0]);
            var height = int.parse (tokens[1]);
            var n_mines = int.parse (tokens[2]);
            var wins = int.parse (tokens[3]);
			var loses = int.parse (tokens[4]);
            statEntries.append (new StatEntry (width, height, n_mines, wins, loses));
        }
    }

    public void save ()
    {
        var contents = "";

        foreach (var entry in entries)
        {
            var line = "%s %u %u %u %u\n".printf (entry.date.to_string (), entry.width, entry.height, entry.n_mines, entry.duration);
            contents += line;
        }

        try
        {
            DirUtils.create_with_parents (Path.get_dirname (filename), 0775);
            FileUtils.set_contents (filename, contents);
        }
        catch (FileError e)
        {
            warning ("Failed to save history: %s", e.message);
        }
		
		contents = "";
		foreach (var statEntry in statEntries)
		{
			var line = "%u %u %u %u %u\n".printf(statEntry.width, statEntry.height, statEntry.n_mines, statEntry.wins, statEntry.loses);
			contents += line;
		}
		
		try
        {
            DirUtils.create_with_parents (Path.get_dirname (statFileName), 0775);
            FileUtils.set_contents (statFileName, contents);
        }
        catch (FileError e)
        {
            warning ("Failed to save statistics: %s", e.message);
        }
    }

	public void reset ()
	{
		entries=new List<HistoryEntry> ();
		try
		{
			FileUtils.unlink(filename);
		}
		catch (FileError e)
		{
			//ignore
		}
		statEntries=new List<StatEntry>();
		try
		{
			FileUtils.unlink(statFileName);
		}
		catch (FileError e)
		{
			//ignore
		}
	}

    private DateTime? parse_date (string date)
    {
        if (date.length < 19 || date[4] != '-' || date[7] != '-' || date[10] != 'T' || date[13] != ':' || date[16] != ':')
            return null;

        var year = int.parse (date.substring (0, 4));
        var month = int.parse (date.substring (5, 2));
        var day = int.parse (date.substring (8, 2));
        var hour = int.parse (date.substring (11, 2));
        var minute = int.parse (date.substring (14, 2));
        var seconds = int.parse (date.substring (17, 2));
        var timezone = date.substring (19);

        return new DateTime (new TimeZone (timezone), year, month, day, hour, minute, seconds);
    }
}

public class HistoryEntry
{
    public DateTime date;
    public uint width;
    public uint height;
    public uint n_mines;
    public uint duration;

    public HistoryEntry (DateTime date, uint width, uint height, uint n_mines, uint duration)
    {
        this.date = date;
        this.width = width;
        this.height = height;
        this.n_mines = n_mines;
        this.duration = duration;
    }
}

public class StatEntry
{
	public uint width;
	public uint height;
	public uint n_mines;
	public uint wins;
	public uint loses;
	public StatEntry(uint width,uint height,uint n_mines,uint wins,uint loses)
	{
		this.width=width;
		this.height=height;
		this.n_mines=n_mines;
		this.wins=wins;
		this.loses=loses;
	}
}