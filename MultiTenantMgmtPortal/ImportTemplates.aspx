<%@ Page Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="ImportTemplates.aspx.vb" Inherits="ManagementPortal.ImportTemplates" %>

<asp:Content ID="Content1" ContentPlaceHolderID="Content" runat="Server">
    <script type="text/javascript">
        function updateButton() {
            document.getElementById('<%=btnImport.ClientID%>').disabled = true;
        }
    </script>
    <asp:ScriptManager ID="ScriptManager1" runat="server">
    </asp:ScriptManager>
    <div id="contentinner" class="base1">
        <div class="toolbar">
            <asp:Button ID="btnImport" runat="server" cssclass="toolbtn" OnClientClick="updateButton();" Text="<%$Resources:Strings, Import %>"
                OnClick="btnImport_Click" UseSubmitBehavior="false" />
            <span class="tooldiv"></span>
            <asp:Button ID="btnBack" runat="server" cssclass="toolbtn" Text="<%$Resources:Strings, Back %>" CausesValidation="false" />
        </div>
        <div class="body">
            <div class="msg" id="msg" runat="server" visible="false">
            </div>
            <table class="editsection" style="width:100%;" role="presentation" border="0">
                <tr>
                    <td style="width:15%;">
                        <asp:Label ID="lblTenantName" runat="server" Text="<%$Resources:Strings, TenantName %>"></asp:Label>
                    </td>
                    <td class="style2" style="width:85%;">
                        <asp:Label ID="lblTenantNameText" runat="server"></asp:Label>
                    </td>
                </tr>                
                <tr>
                    <td colspan="2"><hr /></td>
                </tr>
                <tr>
	                <td colspan="2"><%=Resources.Strings.SampleProjectsInfo%></td>
	            </tr>
	            <tr>
	                <td colspan="2">
	                    <div class="fld" style="height:200px;width:400px;overflow:auto;background-color:white">
	                        <asp:ListBox ID="lstSampleProjects" runat="server" SelectionMode="Multiple"></asp:ListBox>
	                    </div>
	                </td>
                </tr>
             </table>
            <br /><br />
            <asp:GridView ID="grdExistingProjects" runat="server" Width="28%" AutoGenerateColumns="False" EnableViewState="False" CssClass="grd"
                AlternatingRowStyle-CssClass="cell-normal" RowStyle-CssClass="cell-normal" cellspacing="0" cellpadding="1" GridLines="None" 
                Caption="<%$Resources:Strings, ExistingProjectsInfo %>" CaptionAlign="Left" Visible="false">
                <Columns>
                    <asp:BoundField DataField="Name" />
                </Columns>
            </asp:GridView>
        </div>
    </div>
</asp:Content>

