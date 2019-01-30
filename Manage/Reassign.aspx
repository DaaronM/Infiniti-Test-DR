<%@ Page Language="VB" MasterPageFile="~/Manage.master" AutoEventWireup="false" Inherits="Intelledox.Manage.Reassign" Codebehind="Reassign.aspx.vb" %>
<%@ Register TagPrefix="Controls" Namespace="Intelledox.Manage" Assembly="Intelledox.Manage" %>
<asp:Content ID="Content1" ContentPlaceHolderID="Content" runat="Server">
    <script src="Scripts/jquery-3.1.1.min.js" type="text/javascript" ></script>
    <script type="text/javascript">

        function selectUser(obj, id, username) {

            var previous = $("#grdResults .selected-row");

            if (previous.length > 0) {
                previous.toggleClass("selected-row");
            }

            $(obj).closest("tr").addClass("selected-row");
            $("#selectedUser").val(id);
            $("#username").val(username);
        }

    </script>
    <asp:ScriptManager ID="ScriptManager1" runat="server">
    </asp:ScriptManager>
     <div id="contentinner" class="base1">
     <asp:UpdatePanel ID="up" runat="server">
     <ContentTemplate>
        <div class="toolbar">
            <asp:Button ID="btnReassign" runat="server" CssClass="toolbtn" text="<%$Resources:Strings, Reassign %>" />
            <asp:Button ID="btnBack" runat="server" CssClass="toolbtn" text="<%$Resources:Strings, Back %>" />
        </div>
        <div class="body">
            <div class="msg" id="msg" runat="server" visible="false">
            </div>
            <table id="grdResults" width="100%" role="presentation">
                <tr>
                    <td id="tdUserName" class="cell-normal" runat="server"><b><asp:Literal ID="litUserName" runat="server" Text="" /></b></td>
                    <td id="tdLastName" class="cell-normal" runat="server"><b><asp:Literal ID="litLastName" runat="server" Text="<%$Resources:Strings, LastName%>" /></b></td>
                    <td id="tdFirstName" class="cell-normal" colspan="2"  runat="server"><b><asp:Literal ID="litFirstName" runat="server" Text="<%$Resources:Strings, FirstName%>" /></b></td>
                    <td id="tdEmail" class="cell-normal" runat="server"><b><asp:Literal ID="litEmail" runat="server" Text="<%$Resources:Strings, Email%>" /></b></td>
                    <td id="tdFullname" class="cell-normal" colspan="2" runat="server"><b><asp:Literal ID="litFullname" runat="server" Text="<%$Resources:Strings, Fullname%>" /></b></td>
                </tr>
                <tr>
                    <td id="tdUserNameTxt" runat="server"><asp:TextBox id="txtUserName" CssClass="field" style="width:99%" runat="server"/></td>
                    <td id="tdLastNameTxt" runat="server"><asp:TextBox id="txtLastName" CssClass="field" style="width:99%" runat="server"/></td>
                    <td id="tdFirstNameTxt" runat="server"><asp:TextBox id="txtFirstName" CssClass="field" style="width:99%" runat="server"/></td>
                    <td id="tdEmailTxt" runat="server"><asp:TextBox id="txtEmail" CssClass="field" style="width:99%" runat="server"/></td>
                    <td id="tdFullnameTxt" runat="server"><asp:TextBox id="txtFullname" CssClass="field" style="width:99%" runat="server"/></td>
                    <td style="width:80px">
                        <asp:Button id="btnSearch" CssClass="toolbtn" Text="<%$Resources:Strings, Search%>" runat="server" />
                    </td>
                </tr>
                <tr>
                    <td colspan="4">
                        <asp:GridView ID="grdUsers" runat="server" AutoGenerateColumns="False"
                            AlternatingRowStyle-CssClass="cell-normal" RowStyle-CssClass="cell-normal" 
                            CssClass="grd" cellspacing="1" cellpadding="3" GridLines="None" ShowFooter="false" 
                            Width="100%" EnableViewState="false" BorderWidth="0">
                            <Columns>
                                <asp:TemplateField>
                                    <ItemTemplate>
                                        <a href="#void" onclick="selectUser(this, '<%# Eval("UserGuid").ToString() %>', <%# Microsoft.Security.Application.Encoder.JavaScriptEncode(Eval("UserName").ToString()) %>);return false;"><%# Resources.Strings.SelectString %></a>
                                    </ItemTemplate>
                                </asp:TemplateField>
                                <asp:BoundField DataField="UserName" HeaderText="" />
                                <asp:BoundField DataField="LastName" HeaderText="" />
                                <asp:BoundField DataField="FirstName" HeaderText="" />
                            </Columns>
                            <HeaderStyle CssClass="cell-title" />
                            <RowStyle CssClass="cell-normal" />
                            <AlternatingRowStyle CssClass="cell-normal" />
                            <FooterStyle CssClass="cell-footer" />
                            <EmptyDataTemplate><%=Resources.Strings.NoResults %></EmptyDataTemplate>
                        </asp:GridView >
                    </td>
                </tr>
                <tr>
                    <td colspan="4" class="cell-heading"><asp:Literal ID="litComment" runat="server" Text="<%$Resources:Strings, Comment%>" /></td>
                </tr>
                <tr>
                    <td colspan="4" class="cell-normal">
                        <textarea id="txtComments" name="txtComments" cols="20" rows="10" class="field" style="width:99%" runat="server"></textarea>
                    </td>
                </tr>
            </table>
            <input type="hidden" id="selectedUser" name="selectedUser" />
            <input type="hidden" id="username" name="username" />
        </div>
         </ContentTemplate>
        </asp:UpdatePanel>
    </div>
</asp:Content>
    