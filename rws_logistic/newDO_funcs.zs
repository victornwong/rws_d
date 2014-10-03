import org.victor.*;
// Genaral funcs for newDOmanager


void showDO_meta(String ido)
{
	r = getnewDO_rec(ido);
	if(r == null) { guihand.showMessageBox("ERR: cannot access DO table.."); return; }

	Object[] jkl = { customername, d_code, d_shipaddress1, d_shipaddress2, d_shipaddress3, d_shippingcontact, d_shippingphone };
	String[] fl = { "Name", "Code", "ShipAddress1", "ShipAddress2", "ShipAddress3", "ShippingContact", "ShippingPhone"};

	ngfun.populateUI_Data(jkl,fl,r);
}

Object[] dolbhds =
{
	new listboxHeaderWidthObj("RDO",true,"60px"),
	new listboxHeaderWidthObj("Date",true,"70px"),
	new listboxHeaderWidthObj("Customer",true,""),
	new listboxHeaderWidthObj("User",true,"70px"),
};

class dolbClick implements org.zkoss.zk.ui.event.EventListener
{
	public void onEvent(Event event) throws UiException
	{
		isel = event.getReference();
		glob_sel_do = lbhand.getListcellItemLabel(isel,0);
		showDO_meta(glob_sel_do);
	}
}
dolbclkier = new dolbClick();

// itype: 1=by date and search text, 2=by DO
void showDOList(int itype)
{
	last_showdo_type = itype;

	st = kiboo.replaceSingleQuotes(searhtxt_tb.getValue().trim());
	sdate = kiboo.getDateFromDatebox(startdate);
	edate = kiboo.getDateFromDatebox(enddate);
	doid = kiboo.replaceSingleQuotes(doid_tb.getValue().trim());

	Listbox newlb = lbhand.makeVWListbox_Width(do_holder, dolbhds, "do_lb", 3);

	sqlstm = "select top 200 id,entrydate,name,user1 from DeliveryOrderMaster ";

	switch(itype)
	{
		case 1:
			sqlstm += "where entrydate between '" + sdate + " 00:00:00' and '" + edate + " 23:59:00' and name like '%" + st + "%'";
			break;
		case 2:
			sqlstm += "where id=" + doid;
			break;
	}

	sqlstm += " order by entrydate";

	rcs = sqlhand.gpSqlGetRows(sqlstm);
	if(rcs.size() == 0) return;
	newlb.setRows(20); newlb.setMold("paging");
	newlb.addEventListener("onSelect", dolbclkier);
	ArrayList kabom = new ArrayList();
	String[] fl = { "id", "entrydate", "name", "user1" };
	for(d : rcs)
	{
		ngfun.popuListitems_Data(kabom,fl,d);
		lbhand.insertListItems(newlb,kiboo.convertArrayListToStringArray(kabom),"false","");
		kabom.clear();
	}
}

