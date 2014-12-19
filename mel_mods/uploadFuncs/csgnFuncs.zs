import org.victor.*;

// MEL upload consignment note general funcs

Object[] csgnlb_headers =
{
	new listboxHeaderWidthObj("Rec",true,"40px"),
	new listboxHeaderWidthObj("Dated",true,"70px"),
	new listboxHeaderWidthObj("MEL CSGN",true,"90px"),
	new listboxHeaderWidthObj("UplBy",true,"80px"),
	new listboxHeaderWidthObj("Status",true,"70px"),
	new listboxHeaderWidthObj("Notes",true,""),
	new listboxHeaderWidthObj("Qty",true,"50px"),
};

class csgnlbClick implements org.zkoss.zk.ui.event.EventListener
{
	public void onEvent(Event event) throws UiException
	{
		isel = event.getReference();
		glob_sel_csgn = lbhand.getListcellItemLabel(isel,0);
	}
}
csgnclkier = new csgnlbClick();

void loadCSGN(int itype)
{
	last_list_csgn = itype;
	sdate = kiboo.getDateFromDatebox(startdate);
	edate = kiboo.getDateFromDatebox(enddate);

	Listbox newlb = lbhand.makeVWListbox_Width(csgnholder, csgnlb_headers, "csgn_lb", 3);

	sqlstm = "select origid,datecreated,csgn,mel_user,mstatus,extranotes from mel_csgn " +
	"where datecreated between '" + sdate + " 00:00:00' and '" + edate + " 23:59:00'";
	sqlstm += " order by origid";

	rcs = sqlhand.gpSqlGetRows(sqlstm);
	if(rcs.size() == 0) return;
	newlb.setRows(21); newlb.setMold("paging");
	newlb.addEventListener("onSelect", csgnclkier);
	ArrayList kabom = new ArrayList();
	String[] fl = { "origid", "datecreated", "csgn", "mel_user", "mstatus", "extranotes" };
	for(d : rcs)
	{
		ngfun.popuListitems_Data(kabom,fl,d);
		lbhand.insertListItems(newlb,kiboo.convertArrayListToStringArray(kabom),"false","");
		kabom.clear();
	}
}


