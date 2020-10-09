#ifdef PMENU

void(entity ent) PMenu_Update =
{
	if (!ent.client.menu.open)
	{
		gi.dprintf("warning: ent has no menu\n");
		return;
	}
	
	string str = "xv 32 yv 8 picn inventory ";

	for (int i = 0; i < ent.client.menu.num; i++)
	{
		pmenu_t *entry = &ent.client.menu.entries[i];

		if (!entry->text)
			continue; // blank line

		string t = entry->text;
		bool alt;

		if (strat(t, 0) == '*')
		{
			alt = true;
			t = substr(t, 1);
		}
		else
			alt = false;

		str = strconcat(str, "yv ", itos(32 + i * 8), " ");
		
		int x;

		if (entry->align == PMENU_ALIGN_CENTER)
			x = 196/2 - strlen(t)*4 + 64;
		else if (entry->align == PMENU_ALIGN_RIGHT)
			x = 64 + (196 - strlen(t)*8);
		else
			x = 64;

		str = strconcat(str, "xv ", itos(x - ((ent.client.menu.cur == i) ? 8 : 0)), " ");

		if (ent.client.menu.cur == i)
			str = strconcat(str, "string2 \"\x0d", t, "\" ");
		else if (alt)
			str = strconcat(str, "string2 \"", t, "\" ");
		else
			str = strconcat(str, "string \"", t, "\" ");

		if (strlen(str) >= MESSAGE_LIMIT)
		{
			gi.dprintf("menu message length overflow\n");
			return;
		}
	}

	gi.WriteByte(svc_layout);
	gi.WriteString(str);
	gi.unicast(ent, true);
}

void(entity ent) PMenu_Close =
{
	if (!ent.client.menu.open)
		return;

	ent.client.menu.open = false;
	ent.client.showscores = false;
	memclear(&ent.client.menu.entries[0], sizeof(pmenu_t) * 18);
}

void(entity ent, pmenu_t *entries, int num, int cur = -1, void *arg = 0) PMenu_Open =
{
	if (!ent.is_client)
		return;

	if (ent.client.menu.open)
	{
		gi.dprintf("warning: ent already has a menu\n");
		PMenu_Close(ent);
	}

	memcpy(&ent.client.menu.entries[0], entries, sizeof(pmenu_t) * num);
	ent.client.menu.num = num;
	
	int i = cur;

	if (cur < 0 || !entries[cur].func)
		for (i = 0; i < num; i++)
			if (entries[i].func)
				break;

	if (i >= num)
		ent.client.menu.cur = -1;
	else
		ent.client.menu.cur = i;

	ent.client.showscores = true;
	ent.client.menu.open = true;
	ent.client.showinventory = false;
#ifdef SINGLE_PLAYER
	ent.client.showhelp = false;
#endif

	PMenu_Update(ent);
}

inline void(pmenu_t *entry, string text, int align, pmenu_select_func func) PMenu_UpdateEntry =
{
	entry->text = text;
	entry->align = align;
	entry->func = func;
}

void(entity ent, int offset) PMenu_Move =
{
	if (!ent.client.menu.open)
	{
		gi.dprintf("warning: ent has no menu\n");
		return;
	}

	if (ent.client.menu.cur < 0)
		return; // no selectable entries

	int i = ent.client.menu.cur;

	do
	{
		i += offset;

		if (i < 0)
			i = ent.client.menu.num - 1;
		else if (i >= ent.client.menu.num)
			i = 0;

		pmenu_t *p = &ent.client.menu.entries[i];
		
		if (p->func)
			break;
	} while (i != ent.client.menu.cur);

	ent.client.menu.cur = i;

	PMenu_Update(ent);
}

inline void(entity ent) PMenu_Next =
{
	return PMenu_Move(ent, 1);
}

inline void(entity ent) PMenu_Prev =
{
	return PMenu_Move(ent, -1);
}

void(entity ent) PMenu_Select =
{
	if (!ent.client.menu.open)
	{
		gi.dprintf("warning: ent has no menu\n");
		return;
	}

	if (ent.client.menu.cur < 0)
		return; // no selectable entries

	pmenu_t *p = &ent.client.menu.entries[ent.client.menu.cur];

	if (p->func)
		p->func(ent);
}

#endif