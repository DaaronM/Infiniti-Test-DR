<%@ Page Title="" Language="VB" MasterPageFile="~/Manage.master" AutoEventWireup="false" Inherits="Intelledox.Manage.ScheduleProject" Codebehind="ScheduleProject.aspx.vb" %>
<%@ Reference Control="~/Controls/ctlRecurrencePattern.ascx" %>
<%@ Register TagPrefix="uc1" TagName="ctlRecurrencePattern" Src="~/Controls/ctlRecurrencePattern.ascx" %>
<%@ Register TagPrefix="uc2" TagName="ctlDate" Src="~/Controls/ctlDate.ascx" %>
<%@ Register TagPrefix="uc3" TagName="ctlTime" Src="~/Controls/ctlTime.ascx" %>
<asp:Content ID="Content1" ContentPlaceHolderID="Content" Runat="Server">
    <asp:ScriptManager ID="ScriptManager1" runat="server">
    </asp:ScriptManager>
    <div id="contentinner" class="base1">
        <div class="toolbar">
            <asp:Button ID="btnSave" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Save %>" />
            <span class="tooldiv"></span>
            <asp:Button ID="btnBack" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Back %>" CausesValidation="false" />
        </div>
        <asp:UpdatePanel ID="up" runat="server">
            <ContentTemplate>
                <div class="body">
                    <div class="msg" id="msg" runat="server" visible="false">
                    </div>
                    <table align="center" class="editsection" cellspacing="0" role="presentation">
                        <tr>
                            <td><label for="txtName"><%= Resources.Strings.Name%></label></td>
                            <td><asp:TextBox id="txtName" runat="server" CssClass="fld" MaxLength="200" ClientIDMode="Static" />
                                <asp:RequiredFieldValidator ID="valName" runat="server" ErrorMessage="" Display="Dynamic" ControlToValidate="txtName" CssClass="wrn"></asp:RequiredFieldValidator></td>
                        </tr>
                        <tr>
                            <td><label for="txtStartDate"><%= Resources.Strings.StartDate%></label></td>
                            <td><uc2:ctldate id="dteStartDate" TextboxId="txtStartDate" runat="server" CssClass="fld"></uc2:ctldate>
                                <asp:customvalidator id="valStartDate" runat="server" enableclientscript="False" errormessage="<%$Resources:Strings, InvalidStartDate%>" display="Dynamic" CssClass="wrn"></asp:customvalidator></td>
                        </tr>
                        <tr>
                            <td><%= Resources.Strings.StartTime%></td>
                            <td><uc3:ctltime id="dteStartTime" runat="server" CssClass="fld"></uc3:ctltime>
                                <asp:customvalidator id="valStartTime" runat="server" enableclientscript="False" errormessage="<%$Resources:Strings, InvalidStartTime%>" display="Dynamic" CssClass="wrn"></asp:customvalidator></td>
                        </tr>
                        <tr>
                            <td><label for="txtDeleteAfterWait"><%=Resources.Strings.DeleteAfterWait%></label></td>
                            <td><asp:TextBox ID="txtDeleteAfterWait" runat="server" CssClass="fld" MaxLength="4" ClientIDMode="Static"></asp:TextBox>
                                <%=Resources.Strings.Days%>
                                <asp:comparevalidator ID="valDeleteAfterWait" runat="server" ErrorMessage="" Display="Dynamic" ControlToValidate="txtDeleteAfterWait" Type="Integer" ValueToCompare="-1" Operator="GreaterThan" CssClass="wrn" />
                            </td>
                        </tr>
                        <tr>
                            <td class="heading"><label for="chkRecurrence"><%= Resources.Strings.Recurring%></label></td>
                            <td><asp:checkbox id="chkRecurrence" runat="server" autopostback="True" ClientIDMode="Static"></asp:checkbox>
                                <asp:customvalidator id="valRecurrencePattern" runat="server" enableclientscript="False" errormessage="<%$Resources:Strings, InvalidRecurrencePattern%>" display="Dynamic" CssClass="wrn"></asp:customvalidator>
                        </tr>
                        <tr id="trRecurPattern" runat="server" visible="false">
                            <td colspan="2">
                                <uc1:ctlrecurrencepattern id="RecurPattern" runat="server"></uc1:ctlrecurrencepattern>
                                <asp:customvalidator id="valEndByDate" runat="server" enableclientscript="False" errormessage="<%$Resources:Strings, InvalidEndByDate%>" display="Dynamic" CssClass="wrn"></asp:customvalidator>
                            </td>
                        </tr>
                        <tr id="trFolderCheck" runat="server" visible="false">
                            <td class="heading"><label for="chkWatch"><%= Resources.Strings.WatchFolder%></label></td>
                            <td><asp:CheckBox ID="chkWatch" runat="server" AutoPostBack="true" ClientIDMode="Static" /></td>
                        </tr>
                        <tr id="trFolder" runat="server" visible="false">
                            <td>&nbsp;</td>
                            <td>
                                <table role="presentation">
                                    <tr>
                                        <td class="heading"><label for="txtFolder"><%=Resources.Strings.Folder %></label></td>
                                        <td><asp:TextBox ID="txtFolder" runat="server" CssClass="fld" MaxLength="300" ClientIDMode="Static" />
                                        <asp:RequiredFieldValidator ID="valFolder" runat="server" ErrorMessage="" Display="Dynamic" ControlToValidate="txtFolder" CssClass="wrn"></asp:RequiredFieldValidator></td>
                                    </tr>
                                    <tr>
                                        <td class="heading"><label for="lstFileType"><%= Resources.Strings.FileType%></label></td>
                                        <td><asp:DropDownList ID="lstFileType" runat="server" AutoPostBack="true" CssClass="fld" ClientIDMode="Static">
                                        </asp:DropDownList></td>
                                    </tr>
                                    <tr id="trDatasource" runat="server" visible="false">
                                        <td class="heading"><label for="lstDataSource"><%=Resources.Strings.DataSource %></label></td>
                                        <td><asp:DropDownList ID="lstDataSource" runat="server" ClientIDMode="Static">
                                        </asp:DropDownList>
                                        <asp:RequiredFieldValidator ID="valDataSource" runat="server" ErrorMessage="" Display="Dynamic" ControlToValidate="lstDataSource" CssClass="wrn" InitialValue="00000000-0000-0000-0000-000000000000"></asp:RequiredFieldValidator></td>
                                    </tr>
                                </table>
                            </td>
                        </tr>
                    </table>
                </div>
            </ContentTemplate>
        </asp:UpdatePanel>
    </div>
</asp:Content>

