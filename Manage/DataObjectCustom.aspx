<%@ Page Title="" Language="VB" MasterPageFile="~/SubPage.master" AutoEventWireup="false" Inherits="Intelledox.Manage.DataObjectCustom" Codebehind="DataObjectCustom.aspx.vb" %>
<asp:Content ID="Content1" ContentPlaceHolderID="ContentPlaceHolder1" Runat="Server">
    <script type="text/javascript">
        function createCustom() {
            window.opener.createCustom(document.getElementById('txtName').value);
            window.close();
        }
        
        function closeMe() {
            window.close();
        }
    </script>
    <div id="contentinner" class="base1">
        <div class="toolbar">
            <input type="button" id="btnAdd" class="toolbtn" value="<%=Resources.Strings.Add %>" onclick="createCustom()" />
            <input type="button" ID="btnClose" class="toolbtn" value="<%=Resources.Strings.Close %>" onclick="closeMe()" />
        </div>
        <div class="body">
            <%=Resources.Strings.Name%>
            <input type="text" id="txtName" style="width:200px" />
            <br />
        </div>
    </div>
</asp:Content>

